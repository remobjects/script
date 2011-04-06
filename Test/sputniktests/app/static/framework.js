// Copyright 2009 the Sputnik authors.  All rights reserved.
// This code is governed by the BSD license found in the LICENSE file.

var serial = testCaseInfo.serial;
var testCase = new TestCase(null, serial, testCaseInfo);
var runner = new Runner(null, serial, testCase);
var $d = null;

// The type of exception thrown to abort a test.
function testFailed(s) {
  runner.testFailed(s);
}

function testPrint(s) {
  runner.testPrint(s);
  var l = document.createElement('div');
  l.innerHTML = s;
  document.body.appendChild(l);
}

function testDone() {
  runner.testDone();
  if (runner.hasUnexpectedResult()) {
    $d.innerHTML = "<b>" + runner.getMessage() + "</b>";
    $d.style.color = "#700000";
  } else {
    $d.innerHTML = "<b>" + testCase.getName() + " completed</b>";
    $d.style.color = "#007000";
  }
}

function testStart() {
  runner.testStart();
  $d = document.createElement('div');
  $d.style.fontFamily = "sans-serif";
  $d.innerHTML = "<b>Started " + testCase.getName() + "</b>";
  document.body.appendChild($d);
  var l = document.createElement('div');
  l.innerHTML = '<a href="' + serial + '.js">View Source</a>';
  document.body.appendChild(l);
}

function testCompleted() {
  runner.testCompleted();
}
