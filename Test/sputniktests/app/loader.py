#!/usr/bin/python
# Copyright 2009 the Sputnik authors.  All rights reserved.
# This code is governed by the BSD license found in the LICENSE file.


import codecs
import os
import os.path
import re
from google.appengine.tools import bulkloader
import models


def is_hidden(path):
  return path.startswith('.')


def get_test_repository(filename):
  return os.path.join(filename, 'tests', 'Conformance')


def generate_files(filename, limit):
  count = 0
  for (dirpath, dirnames, filenames) in os.walk(get_test_repository(filename)):
    for f in [f for f in dirnames if is_hidden(f)]:
      dirnames.remove(f)
    for f in filenames:
      if not f.endswith('.js') or is_hidden(f):
        continue
      yield os.path.join(dirpath, f)
      count = count + 1
      if limit and count >= limit:
        raise StopIteration


def generate_tests(filename, limit):
  paths = []
  for file in generate_files(filename, limit):
    paths.append(file)
  paths.sort()
  for path in paths:
    yield path


class SputnikLoader(bulkloader.Loader):

  def __init__(self, kind, properties):
    super(SputnikLoader, self).__init__(kind, properties)
    self.attribs = None
    self.files = {}

  def suite(self):
    return self.attribs['suite']

  def get_file_contents(self, path):
    if not path in self.files:
      fullname = os.path.join(self.filename, path)
      if os.path.exists(fullname):
        f = open(fullname)
        contents = f.read()
        f.close()
      else:
        contents = ''
      self.files[path] = contents
    return self.files[path]

  def limit(self):
    val = self.attribs.get('limit')
    if val: return int(val)
    else: return None

  def initialize(self, filename, opts):
    self.attribs = dict([p.split(':') for p in opts.split(',')])
    self.filename = filename


_INCLUDE_PATTERN = re.compile(r'\$INCLUDE\("(.*)"\)')
class CaseLoader(SputnikLoader):

  def __init__(self):
    super(CaseLoader, self).__init__('Case', [
      ('name', str),
      ('suite', str),
      ('source', unicode),
      ('serial', int),
      ('is_negative', bool)
    ])
    self.serial = 0

  def expand_includes(self, contents):
    def replace_include(match):
      name = match.group(1)
      if name == 'environment.js':
        return '$ENVIRONMENT()'
      else:
        return self.get_file_contents(os.path.join('lib', name))
    return re.sub(_INCLUDE_PATTERN, replace_include, contents)

  def to_test_record(self, filename):
    serial = self.serial
    self.serial += 1
    f = codecs.open(filename, "r", "utf-8")
    contents = f.read()
    f.close()
    contents = self.expand_includes(contents)
    name = os.path.basename(filename[:-3])
    is_negative = ('@negative' in contents)
    return [name, self.suite(), contents, serial, str(is_negative)]

  def generate_records(self, filename):
    for case in generate_tests(filename, self.limit()):
      yield self.to_test_record(case)


class SuiteLoader(SputnikLoader):

  def __init__(self):
    super(SuiteLoader, self).__init__('Suite', [
      ('name', str),
      ('count', int)
    ])

  def generate_records(self, filename):
    count = 0
    for case in generate_tests(filename, self.limit()):
      count += 1
    yield [self.suite(), count]


class VersionLoader(SputnikLoader):

  def __init__(self):
    super(VersionLoader, self).__init__('Version', [
      ('current_suite', str)
    ])

  def generate_records(self, filename):
    yield [self.suite()]


loaders = [CaseLoader, SuiteLoader, VersionLoader]
