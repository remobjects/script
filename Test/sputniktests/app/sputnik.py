#!/usr/bin/python
# Copyright 2009 the Sputnik authors.  All rights reserved.
# This code is governed by the BSD license found in the LICENSE file.


import logging
import models
import os.path
import math
import random
import re
import time
from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app
from google.appengine.ext.webapp import template


_DISABLE_CACHING = False


SEC = 1
MIN = 60 * SEC
HOUR = 60 * MIN
INF = 1E400


_MAIN_PAGE_CACHE_SIZE = 256
_MAIN_PAGE_TIMEOUT = 2 * HOUR


_PLOT_CACHE_SIZE = 1024
_PLOT_TIMEOUT = 1 * HOUR


_CHUNK_CACHE_SIZE = 1024
_CHUNK_TIMEOUT = INF


_RESOURCE_CACHE_SIZE = 128
_RESOURCE_TIMEOUT = 24 * HOUR


class RandomCacheEntry(object):

  def __init__(self, value, expiration):
    self._value = value
    self._expiration = expiration

  def is_stale(self):
    return self._expiration < time.time()


class RandomCache(object):
  """A constant-size cache that evicts random elements."""

  def __init__(self, limit = 256, timeout = INF):
    self._index_map = {}
    self._inverse_index = limit * [None]
    self._vector = limit * [None]
    self._limit = limit
    self._timeout = timeout

  def __getitem__(self, key):
    if not key in self._index_map:
      return None
    entry = self._vector[self._index_map[key]]
    if entry.is_stale():
      del self[key]
      return None
    else:
      return entry._value

  def __delitem__(self, key):
    if not key in self._index_map:
      return
    index = self._index_map[key]
    del self._index_map[key]
    self._inverse_index[index] = None
    self._vector[index] = None

  def __setitem__(self, key, value):
    if _DISABLE_CACHING:
      return
    expiration = time.time() + self._timeout
    if key in self._index_map:
      self._vector[self._index_map[key]] = RandomCacheEntry(value, expiration)
    else:
      # Pick an index for this element
      index = random.randint(0, self._limit - 1)
      old_key = self._inverse_index[index]
      if old_key:
        # If the index was occupied we evict the previous value from
        # the index map
        del self._index_map[old_key]
      self._index_map[key] = index
      self._inverse_index[index] = key
      self._vector[index] = RandomCacheEntry(value, expiration)


class Point(object):

  def __init__(self, app, x, y, type):
    self.app = app
    self.x = x
    self.y = y
    self.type = type

  def pull(self, other):
    ideal = self.plotter.distance(self.id, other.id) / 9
    dx = self.x - other.x
    dy = self.y - other.y
    if ideal == 0:
      return [-dx, -dy]
    dist = (ideal - math.sqrt(dx * dx + dy * dy)) / ideal
    return [dx * dist, dy * dist]

  def icon(self):
    return self.app.get_icon(self.type)

  def type(self):
    return self.type


class Sputnik(object):

  def __init__(self):
    self._plot_cache = RandomCache(_PLOT_CACHE_SIZE, _PLOT_TIMEOUT)
    self._main_page_cache = RandomCache(_MAIN_PAGE_CACHE_SIZE, _MAIN_PAGE_TIMEOUT)
    self._chunk_cache = RandomCache(_CHUNK_CACHE_SIZE, _CHUNK_TIMEOUT)
    self._resource_cache = RandomCache(_RESOURCE_CACHE_SIZE, _RESOURCE_TIMEOUT)

  def do_404(self, req):
    req.error(404)

  def do_500(self, req, message):
    req.response.out.write(message)
    req.error(500)

  def set_expiration(self, req, time=3600):
    req.response.headers['cache-control'] = 'max-age=%d' % time

  def get_relative_path(self, name):
    return os.path.join(os.path.dirname(__file__), name)

  def get_dynamic_path(self, name):
    return self.get_relative_path(os.path.join('dynamic', name))

  def get_template(self, name, attribs):
    path = self.get_dynamic_path(name)
    return template.render(path, attribs)

  def get_main_page(self, req, page):
    if not page:
      page = 'about'
    self.set_expiration(req, time=180)
    req.response.headers['Content-Type'] = 'text/html'
    text = self._main_page_cache[page]
    if not text:
      logging.info('Building main %s page' % page)
      version = models.Version.get()
      if not version:
        self.do_500(req, "No current version found")
        return
      current = version.current_suite
      suite = models.Suite.lookup(current)
      if not suite:
        self.do_500(req, "Suite '%s' not found" % current)
        return
      test_suite_version = '2'
      inner = self.get_template('%s.html' % page, {
        'test_suite_version': test_suite_version
      })
      text = self.get_template('page.html', {
        'contents': inner,
        'default_suite_json': suite.to_json(),
        'page_name': '"%s"' % page,
        'test_suite_version': test_suite_version
      })
      self._main_page_cache[page] = text
    req.response.out.write(text)

  def get_test_range_sources(self, req, suite, start, end):
    self.set_expiration(req)
    req.response.headers['Content-Type'] = 'text/javascript'
    key = (suite, start, end)
    text = self._chunk_cache[key]
    if not text:
      logging.info('Building chunk %s-%s for %s' % (start, end, suite))
      chunk = models.Case.lookup_range(suite, int(start), int(end))
      if not chunk:
        return self.do_404(req)
      case_list = [ c.to_json() for c in chunk ]
      text = models.to_json(case_list)
      self._chunk_cache[key] = text
    req.response.out.write(text)

  def get_resource(self, name):
    path = self.get_relative_path(name)
    if os.path.exists(path):
      f = open(path)
      c = f.read()
      f.close()
      return c
    else:
      return ''

  def get_compound_source(self, req, name, type, ext):
    self.set_expiration(req)
    req.response.headers['Content-Type'] = ('text/%s' % type)
    key = (name, ext)
    text = self._resource_cache[key]
    if not text:
      logging.info('Building %s.%s' % (name, ext))
      names = name.split('_')
      sources = []
      for n in names:
        path = os.path.join('resources', '%s.%s' % (n, ext))
        source = self.get_resource(path)
        sources.append(source)
      text = '\n'.join(sources)
      self._resource_cache[key] = text
    req.response.out.write(text)

  def get_css_resource(self, req, name):
    return self.get_compound_source(req, name, 'css', 'css')

  def get_js_resource(self, req, name):
    return self.get_compound_source(req, name, 'javascript', 'js')

  def get_icon(self, type):
    path = self.get_dynamic_path('%s.svg' % type)
    if os.path.exists(path):
      f = open(path)
      c = f.read()
      f.close()
      c = re.sub(r"^(.|[\n])*<!--\s+begin\s+icon\s+-->", "", c, re.MULTILINE)
      c = re.sub(r"<!--\s+end\s+icon\s+-->(.|[\n])*$", "", c, re.MULTILINE)
      return c
    else:
      return ''

  def get_comparison_plot(self, req):
    self.set_expiration(req)
    req.response.headers['Content-Type'] = 'image/svg+xml'
    points = req.request.params.get('m', None)
    key = points
    text = self._plot_cache[key]
    if not text:
      logging.info('Building plot %s' % points)
      map = {
        'bullseye': self.get_icon('bullseye'),
        'tag': self.get_icon('tag')
      }
      if points:
        point_objs = []
        for p in points.split(':'):
          [type, point] = p.split('@')
          [x, y] = point.split(',')
          point_objs.append(Point(self, x, y, type))
        key = points
        map['draw_points'] = True
        map['points'] = point_objs
      else:
        key = 'none'
        map['draw_points'] = False
      text = self.get_template('plot.svg', map)
      self._plot_cache[key] = text
    req.response.out.write(text)


def dispatcher(method, cache=None):
  class Dispatcher(webapp.RequestHandler):
    def get(self, *args):
      return method.__call__(self, *args)
  Dispatcher.__name__ = method.__name__
  return Dispatcher


def initialize_application():
  sputnik = Sputnik()
  return webapp.WSGIApplication([
      ('/(\w*)', dispatcher(sputnik.get_main_page)),
      (r'/cases/(\w+)/(\d+)-(\d+).json', dispatcher(sputnik.get_test_range_sources)),
      (r'/compare/plot.svg', dispatcher(sputnik.get_comparison_plot)),
      (r'/css/([^.]*).css', dispatcher(sputnik.get_css_resource)),
      (r'/js/([^.]*).js', dispatcher(sputnik.get_js_resource))
  ], debug=True)


application = initialize_application()


def main():
  run_wsgi_app(application)


if __name__ == "__main__":
  main()
