// Copyright 2009 the Sputnik authors.  All rights reserved.
// This code is governed by the BSD license found in the LICENSE file.

/*
http://closure-compiler.appspot.com/home

Requires:
goog.require('goog.dom');
goog.require('goog.ui.RoundedPanel');
goog.require('goog.ui.ProgressBar');
goog.require('goog.ui.CustomButton');
goog.require('goog.ui.decorate');
goog.require('goog.ui.Tooltip');
goog.require('goog.net.XhrIo');
*/

var kRotation = 2.14;
var kIterations = 50;
var kTestCaseChunkSize = 128;
var kTestListAppendSize = 640;
var kChunkAheadCount = 2;

var plotter = null;

function gebi(id) {
  return document.getElementById(id);
}

function Persistent(key) {
  this.key_ = key;
  this.hasValue_ = false;
  this.value_ = undefined;
}

Persistent.prototype.fetchFromCookie = function () {
  var parts = document.cookie.split(/\s*;\s*/);
  for (var i = 0; i < parts.length; i++) {
    var part = parts[i];
    if (part.substring(0, this.key_.length) == this.key_) {
      var start;
      if (part.charAt(this.key_.length) == '=') {
        start = this.key_.length + 1;
      } else {
        start = this.key_.length;
      }
      return part.substring(start);
    }
  }
};

Persistent.prototype.get = function () {
  if (!this.hasValue_) {
    this.hasValue_ = true;
    this.value_ = this.fetchFromCookie();
  }
  return this.value_;
};

Persistent.prototype.set = function (value, expiryHoursOpt) {
  this.hasValue_ = true;
  this.value_ = value;
  var expiryHours = expiryHoursOpt || 6;
  var date = new Date();
  date.setTime(date.getTime() + (expiryHours * 60 * 60 * 1000));
  var expiry = "expires=" + date.toGMTString();
  var value = this.key_ + "=" + value + ";" + expiry + "; path=/";
  document.cookie = value;
};

Persistent.prototype.clear = function () {
  document.cookie = this.key_ + "=; path=/";
  this.hasValue_ = true;
  this.value_ = undefined;
};

function TestStatusStore() {
  this.blockStores_ = [];
  this.countStore_ = new Persistent("sputnik_test_count");
  this.storedCount_ = TestStatusStore.DATA_NOT_READ;
}

TestStatusStore.DATA_NOT_READ = -1;

TestStatusStore.prototype.clear = function (signature) {
  this.countStore_.clear();
  this.storedCount_ = 0;
};

function floorBy(val, by) {
  return by * Math.floor(val / by);
}

function encodeBlock(testRun, from, to) {
    var result = [];
  var zeroChunkCount = 0;
  function flushZeroChunks() {
    if (zeroChunkCount == 0) {
      return;
    } else if (zeroChunkCount == 1) {
      result.push(kBase64Chars.charAt(0));
      zeroChunkCount = 0;
    } else {
      result.push('*' + base64Char(zeroChunkCount));
      zeroChunkCount = 0;
    }
  }
  for (var i = from; i < to; i += 6) {
    // Collect the next chunk of 6 test results
    var chunk = 0;
    for (var j = 0; (j < 6) && (i + j < to); j++) {
      var failed = !testRun.getTestStatus(i + j);
      chunk = chunk | ((failed ? 1 : 0) << j);
    }
    if (chunk == 0) {
      if (zeroChunkCount == 63)
        flushZeroChunks();
      zeroChunkCount++;
    } else {
      flushZeroChunks();
      result.push(base64Char(chunk));
    }
  }
  return result.join("");
}

TestStatusStore.prototype.getBlockStore = function (index) {
  if (!(index in this.blockStores_))
    this.blockStores_[index] = new Persistent("sputnik_test_results_" + index);
  return this.blockStores_[index];
};

TestStatusStore.prototype.ensureStoredCount = function () {
  if (this.storedCount_ != TestStatusStore.DATA_NOT_READ)
    return;
  var countStr = this.countStore_.get();
  this.storedCount_ = countStr ? Number(countStr) : 0;
  return this.storedCount_;
};

var kBlockSize = 768;
TestStatusStore.prototype.set = function (testRun, count) {
  this.ensureStoredCount();
  this.countStore_.set(count);
  var blocks = [];
  for (var i = Math.floor(this.storedCount_ / kBlockSize); (i * kBlockSize) < count; i += kBlockSize) {
    var from = i * kBlockSize;
    var to = Math.min(from + kBlockSize, count);
    var block = encodeBlock(testRun, from, to);
    this.getBlockStore(i).set(block);
  }
  this.storedCount_ = count;
};

TestStatusStore.prototype.get = function () {
  this.ensureStoredCount();
  if (this.storedCount_ == 0)
    return null;
  var result = [];
  for (var i = 0; (i * kBlockSize) < this.storedCount_; i++) {
    var block = this.getBlockStore(i).get();
    var remainder = this.storedCount_ - (i * kBlockSize);
    parseTestSignature(Math.min(remainder, kBlockSize), block, result);
  }
  return result;
};

var storedTestRunning = new Persistent("sputnik_test_running");
var storedTestStatus = new TestStatusStore();
var storedBlacklist = new Persistent("sputnik_blacklist");

function Environment() {
  this.cached_ = null;
}

Environment.prototype.get = function () {
  if (!this.cached_)
    this.cached_ = this.calcSource();
  return this.cached_;
};

/**
 * Finds the first date, starting from |start|, where |predicate|
 * holds.
 */
function findNearestDateBefore(start, predicate) {
  var current = start;
  var month = 1000 * 60 * 60 * 24 * 30;
  for (var step = month; step > 0; step = Math.floor(step / 3)) {
    if (!predicate(current)) {
      while (!predicate(current))
        current = new Date(current.getTime() + step);
      current = new Date(current.getTime() - step);
    }
  }
  while (!predicate(current))
    current = new Date(current.getTime() + 1);
  return current;
}

Environment.prototype.calcSource = function () {
  var juneDate = new Date(2000, 6, 20, 0, 0, 0, 0);
  var decemberDate = new Date(2000, 12, 20, 0, 0, 0, 0);
  var juneOffset = juneDate.getTimezoneOffset();
  var decemberOffset = decemberDate.getTimezoneOffset();
  var isSouthernHemisphere = (juneOffset > decemberOffset);
  var winterTime = isSouthernHemisphere ? juneDate : decemberDate;
  var summerTime = isSouthernHemisphere ? decemberDate : juneDate;
  var props = [];
  props.push(['$LocalTZ', new Date().getTimezoneOffset() / -60]);
  function pushDate(type, date) {
    props.push(['$DST_' + type + '_month', date.getMonth()]);
    props.push(['$DST_' + type + '_sunday', date.getDate() > 15 ? '"last"' : '"first"']);
    props.push(['$DST_' + type + '_hour', date.getHours()]);
    props.push(['$DST_' + type + '_minutes', date.getMinutes()]);
  }
  var dstStart = findNearestDateBefore(winterTime, function (date) {
    return date.getTimezoneOffset() == summerTime.getTimezoneOffset();
  });
  pushDate('start', dstStart);
  //  props.push(['$DST_start_month', dstStart.getMonth()]);
  var dstEnd = findNearestDateBefore(summerTime, function (date) {
    return date.getTimezoneOffset() == winterTime.getTimezoneOffset();
  });
  pushDate('end', dstEnd);
  var result = [];
  for (var i = 0; i < props.length; i++) {
    result.push(format('var {{name}} = {{value}};\n', {
      'name': props[i][0],
      'value': props[i][1]
    }));
  }
  return result.join('');
};

var environment = new Environment();

function format(str, props) {
  return str.replace(/\{\{(\w+)\}\}/g, function (full, match) {
    return props[match];
  });
}

function delay(timeoutOpt) {
  var pResult = new Promise();
  var timeout = (timeoutOpt === undefined) ? 0 : timeoutOpt;
  window.setTimeout(function () { pResult.fulfill(null); }, timeout);
  return pResult;
}

function SputnikTestFailed(message) {
  this.message_ = message;
};

function BrowserData(name, type, data) {
  this.name = name;
  this.type = type;
  this.data = data;
  this.signature = new TestRunSignature(this.data);
}

BrowserData.prototype.getSignature = function () {
  return this.signature;
};

BrowserData.prototype.distance = function (other) {
  return calcVectorDistance(this.signature.getVector(), other.signature.getVector());
};

BrowserData.prototype.getTooltipHtml = function () {
  var differences = [];
  for (var i = 0; i < results.length; i++) {
    var result = results[i];
    if (result == this)
      continue;
    var dist = result.distance(this);
    var text = format('<tr><td class="left">{{name}}</td><td class="right"><b>{{score}}</b></td></tr>', {
      'name': result.name,
      'score': result.distance(this)
    });
    differences.push([dist, text]);
  }
  differences.sort(function (a, b) { return a[0] - b[0]; });
  var texts = [];
  for (var i = 0; i < differences.length; i++)
    texts.push(differences[i][1]);
  return format('<div class="scoretip"><div class="scoretipinner"><b>{{label}}</b><br/>Failures: {{count}}</div><table>{{distances}}</table></div>', {
    'label': this.name,
    'count': this.getSignature().getFailureCount(),
    'distances': texts.join('')
  });
};

var results = [
  new BrowserData('Chrome 4.0', 'cm', '5246:*W//fvvB*S/AuxfD*qB*WM*/*/*/*pE*HwgB*DG*JwC*WwB*KM*2g/D*FC*Gg*CB*EQwAgB*KY*JD*FY*CwAG*Hw*Jw*FDD*JMYAYAMEADI*HGE*HB*cgB*DM*HgBAw*CCg*CG*DD*CDAgBAw*CgF*Mg*GG*GD*ED*Ew*QgB*FgB*CM*CgB*CM*CgB*Cw*DD*CM*FM*DGYEAgC*nQ*XgABAEIIAEBCEAQgAIQgABCEIQgABCEIQgABCEACEIQIQIAEEIAgAB'),
  new BrowserData('Firefox 3.6', 'fx', '5246:*W//f/vB*PG*C/AuxfDAwPAwPwB*iB*HCAY*MMg*Jx///D*9gB*FEAE*bg*HC*jQ*FQ*NB*0E*HwgB*DG*JwC*VQ*Eg*HM*18G*FCAC*EQAg*CB*DQQQAghI*CI*GYAC*HDQAI*CYAIwAG*FEAw*EE*Ew*FDD*JMYAYAMEADI*HGE*HB*YE*CCgBC*CM*FkOgBBw*CCgACG*DD*CDAgBAw*CgBAE*Fg*Eg*CC*DGYI*EDAI*CDACDAwAY*OgBAhD*CgB*CM*CgB*CM*CgB*Cw*DD*CM*FM*DGY*/'),
  new BrowserData('Safari 4.0.4', 'sf', '5246:*W51P/v*T/AuBALAIgAIAwB*iB*HCAY*MM*FIi*/*bQ*bC*lQ*FQ*8E*HwgB*DG*JwC*iM*UE*TE*Ng/D*DgACg*DQ*CQAB*DQ*DgZ*LB*JQhBAIAgB*2C*kQ*Kh*Rg*Ca*HE*P6B*DY*HI*/*FEAgC*/gABAEIIAEBCEAQgAIQgABCEIQgABCEIQgABCEACEIQIQIAEEIAgAB'),
  new BrowserData('Internet Explorer 8.0', 'ie', '5246:M*J4Z*EgR*E51P/v*TPBgBALAjuAjOwB*DE*CB*LB*NIAB*HCAY*MM*KO*EDB*CGC*CDBEBAYAYAOAQI*D8//*F/*YwAUG*DBAgAgAEQAC*CEA4K*DE*CQACAh*CCwQ*DEAM*DwQ*DgTC*DYI*DwQ*DYI*DME*DGC*EWC*EWC*EGC*Em*CYCT*DgJ*DwE*Cm*DW*Q8D*L0kCEg*CE*CgwlD*CgO*JwD*O4AgAM*CE*CYO*CI+/f*CtycGjAEwAGE+//////ANAE*QC*CF*CgJf*DQAMgBg/DQAH*Cgg*DQ*IQ*EgIg*IEAC*GgAQ*EE*CIAB*EIAII*FI*CII*DCgg*CC*DI*CQ*RC*RcM*Do*KE*CC*CC*IkPA+f*FQAgg*DQAQa*EEs*CEAC*Eg*EC*CCMAoBZ*GBI*Cg*Gb*GQ*DQ*CsX*gy*Fy*GgC*KE*JgD*RQAg*/'),
  new BrowserData('Opera 10.50', 'op', '5246:*W99//nB*TwPgb83*HE*4M*/*WE*nC*fQ*FQ*1B*ME*HwgB*DG*Jw*jMQI*1I*GC*JB*FE*CgI*/*YS*yBQ*/*/*/')
];

function TestRunSignature(signature) {
  var splitter = signature.indexOf(':');
  this.count_ = parseInt(signature.substring(0, splitter));
  this.data_ = signature.substring(splitter + 1);
  this.vector_ = null;
}

TestRunSignature.prototype.count = function () {
  return this.count_;
};

TestRunSignature.prototype.getVector = function () {
  if (!this.vector_)
    this.vector_ = parseTestSignature(this.count_, this.data_);
  return this.vector_;
};

TestRunSignature.prototype.getFailureCount = function () {
  var vector = this.getVector();
  var count = 0;
  for (var i = 0; i < this.count_; i++) {
    if (!vector[i])
      count++;
  }
  return count;
};

function Plotter(values) {
  this.values = values;
  this.results = [];
  this.matrix = null;
  this.positions = null;
  this.maxScore = null;
}

Plotter.prototype.calcDistanceMatrix = function () {
  for (var i = 0; i < this.values.length; i++)
    this.results.push(this.values[i].getSignature().getVector());
  this.matrix = [];
  for (var i = 0; i < this.results.length; i++)
    this.matrix[i] = [];
  for (var i = 0; i < this.results.length; i++) {
    this.matrix[i][i] = 0.0;
    for (var j = 0; j < i; j++) {
      var dist = calcVectorDistance(this.results[i], this.results[j]);
      this.matrix[i][j] = dist;
      this.matrix[j][i] = dist;
    }
  }
  var scores = [];
  for (var i = 0; i < this.results.length; i++)
    scores.push(calcScore(this.results[i]));
  return scores;
};

Plotter.prototype.calcInitialPositions = function (scores) {
  var clusters = [];
  for (var i = 0; i < this.values.length; i++)
    clusters.push(new Cluster(this, scores, [i], null, null));
  while (clusters.length > 1) {
    var minDist = null;
    var minI = null;
    var minJ = null;
    for (var i = 0; i < clusters.length; i++) {
      for (var j = 0; j < i; j++) {
        var a = clusters[i];
        var b = clusters[j];
        var dist = a.distanceTo(b);
        if ((minDist === null) || (dist < minDist)) {
          minDist = dist;
          minI = i;
          minJ = j;
        }
      }
    }
    var a = clusters[minI];
    var b = clusters[minJ];
    var newValues = a.values.concat(b.values);
    var next = new Cluster(this, scores, newValues, a, b);
    var newClusters = [];
    for (var i = 0; i < clusters.length; i++) {
      if (i != minI && i != minJ)
        newClusters.push(clusters[i]);
    }
    newClusters.push(next);
    clusters = newClusters;
  }
  this.positions = [];
  this.maxScore = 0;
  for (var i = 0; i < scores.length; i++)
    this.maxScore = Math.max(scores[i], this.maxScore);
  this.positionCluster(0, 2 * Math.PI, clusters[0]);
};

Plotter.prototype.positionCluster = function (from, to, cluster) {
  if (cluster.values.length == 1) {
    var scale = cluster.score() / this.maxScore * 100;
    var index = cluster.values[0];
    var pos = (from + to) / 2;
    var x = Math.sin(pos + kRotation) * scale;
    var y = Math.cos(pos + kRotation) * scale;
    this.positions.push(new Point(this, index, x, y, this.values[index]));
  } else {
    var ratio = cluster.leftChild.size() / cluster.size();
    var mid = (to - from) * ratio;
    this.positionCluster(from, from + mid, cluster.leftChild);
    this.positionCluster(from + mid, to, cluster.rightChild);
  }
};

Plotter.prototype.distance = function (i, j, scores) {
  if (i == -1) {
    return scores[j];
  } else if (j == -1) {
    return scores[i];
  } else {
    return this.matrix[i][j];
  }
};

Plotter.prototype.dampen = function (pull, temp) {
  var dx = pull[0];
  var dy = pull[1];
  var length = Math.sqrt(dx * dx + dy * dy);
  if (length > temp) {
    var ratio = temp / length;
    pull[0] *= ratio;
    pull[1] *= ratio;
  }
};

Plotter.prototype.runLassesSpringyAlgorithm = function (scores, adjustCenter) {
  // First apply springy algorithm to adjust positions to match distances.
  var center = new Point(this, -1, 0, 0, null);
  this.positions.push(center);
  var count = this.positions.length;
  var max = 20 / count;
  for (var l = 0; l < kIterations; l++) {
    var temp = max * (1 - (l / kIterations));
    var pulls = [];
    // Calculate the pull that each exerts on the other
    for (var i = 0; i < count; i++)
      pulls[i] = [];
    for (var i = 0; i < count; i++) {
      for (var j = 0; j < count; j++) {
        var pull = this.positions[i].calcPull(this.positions[j], scores);
        this.dampen(pull, temp);
        pulls[i][j] = pull;
      }
    }
    // Apply the pull to the points
    for (var i = 0; i < count; i++) {
      for (var j = 0; j < count; j++) {
        if (i == j || this.positions[i].isFixed) continue;
        var pull = pulls[i][j];
        this.positions[i].x += pull[0];
        this.positions[i].y += pull[1];
      }
    }
  }
  this.positions.pop();
  // Push points out so distance to center matches score
  for (var i = 0; i < count - 1; i++) {
    var point = this.positions[i];
    var x = point.x - center.x;
    var y = point.y - center.y;
    var dist = Math.sqrt(x * x + y * y);
    if (dist == 0)
      continue;
    var idealDist = scores[point.id] / this.maxScore * 100;
    var factor = idealDist / dist;
    point.x *= factor;
    point.y *= factor;
  }
  if (adjustCenter) {
    // Then move all the points to get the midpoint to (0, 0)
    for (var i = 0; i < this.positions.length; i++) {
      var point = this.positions[i];
      point.x -= center.x;
      point.y -= center.y;
    }
  }
  var maxDist = 0;
  for (var i = 0; i < this.positions.length; i++) {
    var point = this.positions[i];
    var dist = Math.sqrt(point.x * point.x + point.y * point.y);
    maxDist = Math.max(maxDist, dist);
  }
  // Then scale to get the farthes point to a distance of 100.
  var ratio = 100 / maxDist;
  for (var i = 0; i < this.positions.length; i++) {
    var point = this.positions[i];
    point.x *= ratio;
    point.y *= ratio;
  }
  return center;
};

Plotter.prototype.getUrl = function () {
  var result = [];
  for (var i = 0; i < this.positions.length; i++) {
    var pos = this.positions[i];
    result.push(pos.data.type + "@" + (pos.x << 0) + "," + (pos.y << 0));
  }
  return result.join(":");
};

Plotter.prototype.placeFixpoints = function () {
  var scores = this.calcDistanceMatrix();
  this.calcInitialPositions(scores);
  this.runLassesSpringyAlgorithm(scores, true);
  for (var i = 0; i < this.positions.length; i++)
    this.positions[i].isFixed = true;
};

var plot;
Plotter.prototype.displayOn = function (root) {
  var elm = document.createElement('object', true);
  elm.setAttribute('width', 450);
  elm.setAttribute('height', 450);
  elm.setAttribute('data', "compare/plot.svg?m=" + this.getUrl());
  elm.setAttribute('type', "image/svg+xml");
  elm.setAttribute('id', 'plot');
  elm.setAttribute('onload', 'plotLoaded()');
  svgweb.appendChild(elm, root);
  plot = root;
};

function PopUpController() {
  this.elm_ = document.createElement('div');
  this.elm_.className = 'popup';
  this.hide();
  this.timeout_ = 500;
  this.hasScheduledTimeout_ = false;
  this.lastMouseMove_ = new Date();
  this.lastEvent_ = null;
  this.lastCallback_ = null;
  this.isShowingPopup_ = false;
  this.hasLeft_ = false;
}

PopUpController.prototype.hide = function () {
  this.elm_.style.visibility = 'hidden';
  this.isShowingPopup_ = false;
};

PopUpController.prototype.show = function (event, callback) {
  var popup = this.elm_;
  var x = event.clientX;
  var y = event.clientY;
  popup.innerHTML = callback();
  popup.style.left = x + 95 + 10 + 'px';
  popup.style.top = y + 10 + 10 + 'px';
  popup.style.visibility = 'visible';
  this.isShowingPopup_ = true;
};

PopUpController.prototype.decorate = function (root) {
  root.appendChild(this.elm_);
};

PopUpController.prototype.checkTimeout = function (whenScheduled, callback) {
  if (this.hasLeft_)
    return;
  var now = new Date();
  var lastMove = this.lastMouseMove_;
  if (lastMove != whenScheduled) {
    var elapsed = now - lastMove;
    this.hasScheduledTimeout_ = true;
    delay(Math.max(this.timeout_ - elapsed, 0)).onValue(this, function () {
      this.hasScheduledTimeout_ = false;
      this.checkTimeout(lastMove, callback);
    });
  } else {
    this.show(this.lastEvent_, this.lastCallback_);
  }
};

PopUpController.prototype.elementMouseMoved = function (elm, event, callback) {
  if (this.hasLeft_)
    return;
  if (this.isShowingPopup_) {
    this.hide();
  } else {
    var now = new Date();
    this.lastMouseMove_ = now;
    this.lastEvent_ = event;
    this.lastCallback_ = callback;
    if (!this.hasScheduledTimeout_) {
      this.hasScheduledTimeout_ = true;
      delay(this.timeout_).onValue(this, function () {
        this.hasScheduledTimeout_ = false;
        this.checkTimeout(now, callback);
      });
    }
  }
};

PopUpController.prototype.attach = function (elm, callback) {
  var self = this;
  elm.onmousemove = function (event) {
    self.hasLeft_ = false;
    self.elementMouseMoved(elm, event, callback);
  };
  elm.onmouseout = function (event) {
    self.hasLeft_ = true;
    self.hide();
  }
};

function plotLoaded() {
  var controller = new PopUpController();
  controller.decorate(plot);
  var doc = gebi('plot').contentDocument;
  for (var i = 0; i < results.length; i++) {
    var result = results[i];
    var elm = doc.getElementById(result.type);
    elm.style.cursor = 'pointer';
    (function (r) {
      controller.attach(elm, function () {
        return r.getTooltipHtml();
      });
    })(result);
  }
}

Plotter.prototype.placeByDistance = function (distances) {
  return this.runLassesSpringyAlgorithm(distances, false);
};

function Point(plotter, id, x, y, data) {
  this.plotter = plotter;
  this.id = id;
  this.x = x;
  this.y = y;
  this.data = data;
  this.isFixed = false;
}

Point.prototype.toString = function () {
  return "(" + this.x + ", " + this.y + ")";
};

Point.prototype.calcPull = function (other, scores) {
  var ratio = (100 / this.plotter.maxScore);
  var ideal = this.plotter.distance(this.id, other.id, scores) * ratio;
  var dx = this.x - other.x;
  var dy = this.y - other.y;
  if (ideal == 0) {
    return [-dx, -dy];
  } else {
    var force = (ideal - Math.sqrt(dx * dx + dy * dy)) / ideal / 2;
    return [dx * force, dy * force];
  }
};

function Cluster(plotter, scores, values, leftChild, rightChild) {
  this.scores = scores;
  this.plotter = plotter;
  this.values = values;
  this.leftChild = leftChild;
  this.rightChild = rightChild;
}

Cluster.prototype.score = function () {
  return this.scores[this.values[0]];
};

Cluster.prototype.toString = function () {
  if (this.leftChild === null) {
    return this.plotter.values[this.values[0]].name + "(" + this.values[0] + ")";
  } else {
    return "(" + this.leftChild + " " + this.rightChild + ")";
  }
};

Cluster.prototype.size = function () {
  return this.values.length;
};

Cluster.prototype.distanceTo = function (other) {
  var sum = 0;
  var count = 0;
  for (var i = 0; i < this.values.length; i++) {
    for (var j = 0; j < other.values.length; j++) {
      sum += this.plotter.distance(this.values[i], other.values[j]);
      count += 1;
    }
  }
  return sum / count;
};

function matrixToString(keys, scores, matrix) {
  var result = '';
  for (var i = 0; i < keys.length; i++) {
    if (i > 0) result += ",";
    result += keys[i];
  }
  result += ":";
  for (var i = 0; i < keys.length; i++) {
    if (i > 0) result += ",";
    result += scores[i];
  }
  for (var i = 1; i < matrix.length; i++) {
    result += ":";
    for (var j = 0; j < i; j++) {
      if (j > 0) result += ",";
      result += matrix[i][j];
    }
  }
  return result;
}

function calcScore(a) {
  var result = 0;
  for (var i = 0; i < a.length; i++) {
    if (!a[i])
      result++;
  }
  return result;
}

function calcVectorDistance(a, b) {
  var minLength = Math.min(a.length, b.length);
  var result = 0;
  for (var i = 0; i < minLength; i++) {
    if (a[i] != b[i])
      result++;
  }
  var longest = (a.length > b.length) ? a : b;
  for (; i < longest.length; i++) {
    if (!longest[i])
      result++;
  }
  return result;
}

function jsonDebugToString() {
  var parts = [];
  for (var name in this) {
    var value = this[name];
    if (typeof value == 'function')
      continue;
    parts.push(name + " = " + value);
  }
  return "json {" + parts.join(", ") + "}"
}

function parseJson(str) {
  var result;
  if (typeof JSON != 'undefined') result = JSON.parse(str);
  else result = eval("(" + str + ")");
  try {
    result.__proto__ = {'toString': jsonDebugToString};
  } catch (e) {
    // ignore
  }
  return result;
}

function reportError(str) {
  alert(str);
}

function assert(value) {
  if (!value) {
    alert("Assertion failed");
    (undefined).foo; // force debugger
  }
}

// --- R u n n e r ---

var runnerTraits = { };

function inheritTraits(fun, traits) {
  for (var name in traits)
    fun.prototype[name] = traits[name];
}

runnerTraits.openTestPage = function () {
  window.open(this.testCase_.getHtmlUrl(), '_blank');
}

function MockRunner(serial, result) {
  this.serial_ = serial;
  this.result_ = result;
}

inheritTraits(MockRunner, runnerTraits);

MockRunner.prototype.hasUnexpectedResult = function () {
  return !this.result_;
};

MockRunner.prototype.getMessage = function () {
  return "Test " + this.serial_ + " failed.";
};

function Runner(testRun, serial, testCase) {
  this.testRun_ = testRun;
  this.serial_ = serial;
  this.testCase_ = testCase;
  this.root_ = document.getElementById('workerRoot');
  this.iframe_ = document.createElement('iframe');
  this.pResult_ = new Promise();
  this.start_ = null;
  this.hasFailed_ = false;
  this.hasCompleted_ = false;
  this.failedMessage_ = null;
  this.printed_ = [];
}

inheritTraits(Runner, runnerTraits);

Runner.prototype.testPrint = function (str) {
  this.printed_.push(str);
};

Runner.prototype.getName = function () {
  return this.testCase_.getName();
};

Runner.prototype.getMessage = function () {
  assert(this.hasUnexpectedResult());
  if (this.hasFailed()) {
    if (this.failedMessage_) {
      return this.failedMessage_;
    } else {
      return this.getName() + " failed";
    }
  } else {
    return this.getName() + " was expected to fail";
  }
};

Runner.prototype.hasFailed = function () {
  return this.hasFailed_;
};

Runner.prototype.testStart = function () {
  this.start_ = new Date();
  storedTestRunning.set(this.serial_);
};

Runner.prototype.testDone = function () {
  if (!this.hasCompleted_)
    this.hasFailed_ = true;
  if (this.testRun_)
    this.testRun_.testDone(this);
  this.pResult_.fulfill(null);
  if (this.root_)
    this.root_.removeChild(this.iframe_);
};

Runner.prototype.testCompleted = function () {
  this.hasCompleted_ = true;
};

Runner.prototype.testFailed = function (message) {
  this.recordFailure(message);
  throw new SputnikTestFailed(message);
};

Runner.prototype.recordFailure = function (message) {
  if (!this.hasFailed_) {
    this.hasFailed_ = true;
    this.failedMessage_ = message;
  }
};

Runner.prototype.hasUnexpectedResult = function () {
  var hasSucceeded = this.hasCompleted_ && !this.hasFailed_;
  var isPositive = !this.testCase_.isNegative();
  return isPositive !== hasSucceeded;
};

Runner.prototype.inject = function (code) {
  var doc = this.iframe_.contentWindow.document;
  try {
    doc.write('<script>' + code + '</script>');
  } catch (e) {
    this.recordFailure(String(e));
  }
};

Runner.prototype.schedule = function () {
  var source = this.testCase_.getSource();
  this.root_.appendChild(this.iframe_);
  var self = this;
  var global = this.iframe_.contentWindow;
  this.inject('');
  global.testFailed = function (s) { self.testFailed(s); };
  global.testDone = function () { self.testDone(); };
  global.testStart = function () { self.testStart(); };
  global.testCompleted = function () { self.testCompleted(); };
  global.testPrint = function () { self.testPrint(); };
  this.inject('testStart();');
  this.inject(source);
  this.inject('testDone();');
  return this.pResult_;
};

Runner.prototype.toString = function () {
  return "a Runner(" + this.serial_ + ")";
};

// --- T e s t   R e s u l t ---

function cloneJson(obj) {
  if (typeof obj == 'object') {
    var clone = { };
    for (var p in obj)
      clone[p] = cloneJson(obj[p]);
    return clone;
  } else {
    return obj;
  }
}

function TestResult(info) {
  // Note that since a JSON literal may (and in v8 will) keep the
  // surrounding page's context alive we do a clone here and throw the
  // original object away.
  this.info = cloneJson(info);
  this.status = TestResult.RUNNING;
  this.message = null;
}

TestResult.prototype.asExpected = function () {
  return (this.status == TestResult.COMPLETED) || this.info.isNegative;
};

TestResult.RUNNING = "running";
TestResult.COMPLETED = "completed";
TestResult.FAILED = "failed";
TestResult.ABORTED = "aborted";

// --- T e s t   R u n ---

function Promise(valueOpt) {
  this.hasValue = false;
  this.value = undefined;
  this.onValues = [];
};

Promise.prototype.fulfill = function (value) {
  this.hasValue = true;
  this.value = value;
  this.fire();
};

Promise.prototype.fire = function () {
  for (var i = 0; i < this.onValues.length; i++) {
    var pair = this.onValues[i];
    pair[1].call(pair[0], this.value);
  }
  this.onValues.length = 0;
};

Promise.prototype.onValue = function (self, fun) {
  if (this.hasValue) {
    fun.call(self, this.value);
  } else {
    this.onValues.push([self, fun]);
  }
};

function makeRequest(path) {
  var pResult = new Promise();
  goog.net.XhrIo.send(path, function () {
    var obj = this.getResponseJson();
    pResult.fulfill(obj);
  }, 'GET', undefined, undefined, 0);
  return pResult;
}

function TestCase(run, serial, data) {
  this.run_ = run;
  this.serial_ = serial;
  this.data_ = data;
  this.description_ = null;
}

TestCase.prototype.getHtmlUrl = function () {
  var suite = this.run_.getSuiteName();
  return "cases/" + suite + "/" + this.serial_ + ".html";
};

TestCase.prototype.getSource = function () {
  var rawSource = this.data_.source;
  var source = rawSource.replace(/\$ERROR/g, 'testFailed');
  source = source.replace(/\$FAIL/g, 'testFailed');
  source = source.replace(/\$PRINT/g, 'testPrint');
  source = source.replace(/\$ENVIRONMENT\(\)/g, environment.get());
  source += "\ntestCompleted();";
  return source;
};

TestCase.prototype.getName = function () {
  return this.data_.name;
};

TestCase.prototype.getSerial = function () {
  return this.serial_;
};

TestCase.prototype.getDescription = function () {
  if (!this.description_) {
    var result;
    var match = /@description:(.*)$/m.exec(this.data_.source);
    if (!match) {
      result = "";
    } else {
      var str = match[1];
      var stripped = /^\s*(.*)\s*;$/.exec(str);
      result = stripped ? stripped[1] : str;
    }
    this.description_ = result;
  }
  return this.description_;
};

TestCase.prototype.isNegative = function () {
  return this.data_.isNegative;
};

TestCase.prototype.toString = function() {
  return "a TestCase { id = " + this.serial_ + " }";
};

function TestChunk(run, from, to) {
  this.run_ = run;
  this.from_ = from;
  this.to_ = to;
  this.state_ = TestChunk.EMPTY;
  this.pLoaded_ = new Promise();
  this.data_ = null;
};

TestChunk.EMPTY = "empty";
TestChunk.LOADING = "loading";
TestChunk.LOADED = "loaded";

TestChunk.prototype.ensureLoaded = function () {
  if (this.state_ === TestChunk.EMPTY) {
    this.state_ = TestChunk.LOADING;
    var path = 'cases/' + this.run_.getSuiteName() + '/' + this.from_ + '-' + this.to_ + '.json';
    var pGotRequest = makeRequest(path);
    pGotRequest.onValue(this, function (value) {
      this.state_ = TestChunk.LOADED;
      for (var i = this.from_; i < this.to_; i++)
        this.run_.registerCase(i, new TestCase(this.run_, i, value[i - this.from_]));
      this.pLoaded_.fulfill(null);
    });
  }
  return this.pLoaded_;
};

function TestQuery(suite) {
  this.suite_ = suite;
  this.chunks_ = [];
  this.cases_ = {};
  this.initializeChunks();
}

TestQuery.prototype.getSize = function () {
  return this.suite_.count;
};

TestQuery.prototype.initializeChunks = function () {
  var count = this.suite_.count;
  for (var i = 0, c = 0; i < count; i += kTestCaseChunkSize, c++) {
    var to = Math.min(i + kTestCaseChunkSize, count);
    var chunk = new TestChunk(this, i, to);
    this.chunks_[c] = chunk;
  }
};

TestQuery.prototype.registerCase = function (index, test) {
  this.cases_[index] = test;
};

TestQuery.prototype.ensureChunkLoaded = function (index) {
  var result = this.chunks_[index].ensureLoaded();
  var limit = Math.min(index + kChunkAheadCount + 1, this.chunks_.length);
  for (var i = index + 1; i < limit; i++)
    this.chunks_[i].ensureLoaded();
  return result;
};

TestQuery.prototype.getTestCase = function (index) {
  var pResult = new Promise();
  var chunkIndex = Math.floor(index / kTestCaseChunkSize);
  var pLoadedTestCases = this.ensureChunkLoaded(chunkIndex);
  pLoadedTestCases.onValue(this, function () {
    pResult.fulfill(this.cases_[index]);
  });
  return pResult;
};

TestQuery.prototype.getEntry = function (serial) {
  var pResult = new Promise();
  this.getTestCase(serial).onValue(this, function (test) {
    pResult.fulfill(toDataEntry(test, TestPanelEntry.NONE));
  });
  return pResult;
};

TestQuery.prototype.getSuiteName = function () {
  return this.suite_.name;
};

TestQuery.prototype.size = function () {
  return this.suite_.count;
}

function TestRun(data, progress) {
  this.current_ = 0;
  this.progress_ = progress;
  this.data_ = data;
  this.doneCount_ = 0;
  this.failedTests_ = [];
  this.succeededCount_ = 0;
  this.runs_ = {};
  this.abort_ = false;
  this.passFailVector_ = [];
  this.paused_ = false;
  this.displayResults_ = false;
}

TestRun.prototype.resume = function () {
  this.paused_ = false;
  this.scheduleNextTest();
};

TestRun.prototype.pause = function () {
  this.paused_ = true;
};

TestRun.prototype.runTest = function (serial, testCase) {
  return new Runner(this, serial, testCase).schedule();
};

TestRun.prototype.calculateCurrentDistances = function (plotter) {
  var dists = [];
  var results = this.passFailVector_;
  for (var i = 0; i < plotter.results.length; i++) {
    var dist = calcVectorDistance(results, plotter.results[i]);
    dists.push(dist);
  }
  return dists;
};

TestRun.prototype.scheduleNextTest = function () {
  if (this.paused_)
    return;
  while (blacklist.contains(this.current_)) {
    var serial = this.current_++;
    this.addMockTest(serial, true);
  }
  if (this.current_ >= this.size())
    return;
  var serial = this.current_++;
  var pDelay = delay();
  pDelay.onValue(this, function () {
    var pCase = this.getTestCase(serial);
    pCase.onValue(this, function (value) {
      var pDoneRunning = this.runTest(serial, value);
      pDoneRunning.onValue(this, function () {
        this.scheduleNextTest();
      });
    });
  });
};

TestRun.prototype.getTestCase = function (serial) {
  return this.data_.getTestCase(serial);
};

TestRun.prototype.size = function () {
  return this.data_.size();
};

function parseTestResults(progress) {
  var splitter = progress.indexOf(':');
  var count = parseInt(progress.substring(0, splitter));
  var data = progress.substring(splitter + 1);
  var bits = parseTestSignature(count, data);
  assert(count == bits.length);
  return bits;
}

function Blacklist(store) {
  this.store_ = store;
  var str = store.get();
  if (str) {
    this.value_ = str.split(':');
  } else {
    this.value_ = [];
  }
  this.map_ = {};
  this.transientMap_ = {};
  for (var i = 0; i < this.value_.length; i++) {
    this.map_[this.value_[i]] = true;
  }
};

Blacklist.prototype.initialize = function () {
  // If we were interrupted add the test to the blacklist
  var str = storedTestRunning.get();
  storedTestRunning.clear();
  if (str)
    this.push(str);
  // Add tests from URL parameters
  var fromUrl = getUrlParameters()['skip'];
  if (fromUrl) {
    var skipped = fromUrl.split(',');
    for (var i = 0; i < skipped.length; i++)
      this.pushTransient(skipped[i]);
  }
};

Blacklist.prototype.push = function (i) {
  if (this.contains(i))
    return;
  this.value_.push(i);
  this.store_.set(this.value_.join(':'));
  this.map_[i] = true;
};

Blacklist.prototype.pushTransient = function (i) {
  this.transientMap_[i] = true;
};

Blacklist.prototype.contains = function (value) {
  return !!this.map_[value] || !!this.transientMap_[value];
};

var blacklist = new Blacklist(storedBlacklist);

TestRun.prototype.addMockTest = function (i, hasFailed) {
  var runner = new MockRunner(i, hasFailed);
  this.testDone(runner, true);
};

TestRun.prototype.fastForward = function (bits) {
  // We force the last test to have been failed.
  for (var i = 0; i < bits.length; i++)
    this.addMockTest(i, bits[i]);
  this.current_ = bits.length;
  this.updateUi();
};

TestRun.prototype.setTestList = function (testList) {
  this.testList_ = testList;
};

TestRun.prototype.updateUi = function () {
  this.progress_.setValue((100 * this.doneCount_ / this.size()) | 0);
  this.testList_.addPendingEntries();
  document.getElementById('failed').innerHTML = this.failedTests_.length;
  document.getElementById('succeeded').innerHTML = this.succeededCount_;
  document.getElementById('total').innerHTML = this.doneCount_;
};

var kBase64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

function base64Char(index) {
  assert(0 <= index);
  assert(index < kBase64Chars.length);
  return kBase64Chars.charAt(index);
}

function indexOfBase64Char(c) {
  var result = kBase64Chars.indexOf(c);
  assert(result != -1);
  return result;
}

TestRun.prototype.getTestStatus = function (index) {
  return this.passFailVector_[index];
};

TestRun.prototype.getFailedBits = function (count) {
  var result = [];
  for (var i = 0; i < count; i++)
    result[i] = this.getTestStatus(i);
  return result;
};

TestRun.prototype.getSignature = function (count) {
  var result = [];
  var zeroChunkCount = 0;
  function flushZeroChunks() {
    if (zeroChunkCount == 0) {
      return;
    } else if (zeroChunkCount == 1) {
      result.push(kBase64Chars.charAt(0));
      zeroChunkCount = 0;
    } else {
      result.push('*' + base64Char(zeroChunkCount));
      zeroChunkCount = 0;
    }
  }
  for (var i = 0; i < count; i += 6) {
    // Collect the next chunk of 6 test results
    var chunk = 0;
    for (var j = 0; (j < 6) && (i + j < count); j++) {
      var failed = !this.getTestStatus(i + j);
      chunk = chunk | ((failed ? 1 : 0) << j);
    }
    if (chunk == 0) {
      if (zeroChunkCount == 63)
        flushZeroChunks();
      zeroChunkCount++;
    } else {
      flushZeroChunks();
      result.push(base64Char(chunk));
    }
  }
  var data = result.join("");
  assert(String(parseTestSignature(count, data)) == String(this.getFailedBits(count)));
  return count + ":" + data;
};

function parseTestSignature(count, data, result) {
  var i = 0;
  if (!result)
    result = [];
  var bitsRead = 0;
  while (i < data.length) {
    var c = data.charAt(i++);
    if (c == '*') {
      var next = data.charAt(i++);
      var zeroChunkCount = indexOfBase64Char(next);
      for (var j = 0; j < 6 * zeroChunkCount; j++) {
        result.push(true);
        bitsRead++;
      }
    } else {
      var bits = indexOfBase64Char(c);
      for (var j = 0; j < 6 && bitsRead < count; j++) {
        result.push((bits & (1 << j)) == 0);
        bitsRead++;
      }
    }
  }
  while (bitsRead < count) {
    result.push(true);
    bitsRead++;
  }
  return result;
}

TestRun.prototype.allDone = function () {
  if (this.displayResults_) {
    var signature = this.getSignature(this.data_.getSize());
    var sigDiv = document.createElement('div');
    sigDiv.innerHTML = "Results: [" + signature + "]";
    document.body.appendChild(sigDiv);
  }
  this.progress_.setText("Done");
  testControls.allDone();
};

TestRun.prototype.updateCounts = function (runner, silent) {
  this.doneCount_++;
  var hadUnexpectedResult = runner.hasUnexpectedResult();
  this.passFailVector_[runner.serial_] = !hadUnexpectedResult;
  if (hadUnexpectedResult) {
    this.failedTests_.push(runner.serial_);
    var message = runner.getMessage();
    function onErrorClicked() { runner.openTestPage(); }
    this.reportFailure(this, onErrorClicked, message);
  } else {
    this.succeededCount_++;
  }
  if (!silent) {
    storedTestStatus.set(this, runner.serial_ + 1);
  }
};

TestRun.prototype.testDone = function (runner, silent) {
  this.updateCounts(runner, silent);
  if (!silent)
    this.updateUi();
  if (this.doneCount_ >= this.size()) {
    // Complete the test run on a timeout to allow the ui to update with
    // the last results first.
    var pDelay = delay();
    pDelay.onValue(this, function () {
      this.allDone();
    });
  }
};

TestRun.prototype.getResultData = function () {
  return new TestRunData(this);
};

TestRun.prototype.reportFailure = function (self, fun, message) {

};

function TestRunData(run) {
  this.run_ = run;
}

TestRunData.prototype.size = function () {
  return this.run_.failedTests_.length;
};

function toDataEntry(test, status) {
  return {
    getName: function () { return test.getName(); },
    getDescription: function () { return test.getDescription(); },
    getSource: function () { return test.getSource(); },
    getStatus: function () { return status; }
  };
}

TestRunData.prototype.getEntry = function (serial) {
  var pResult = new Promise();
  this.run_.getTestCase(this.run_.failedTests_[serial]).onValue(this, function (test) {
    var isBlacklisted = blacklist.contains(test.getSerial());
    var status = isBlacklisted ? TestPanelEntry.BLACKLISTED : TestPanelEntry.FAILED;
    pResult.fulfill(toDataEntry(test, status));
  });
  return pResult;
};

function moreInfo() {
  gebi('runDetails').className = undefined;
}

function TestPanel(data, element) {
  this.data_ = data;
  this.entries_ = [];
  this.element_ = element;
  this.targetCount_ = kTestListAppendSize;
  this.decorate();
}

TestPanel.prototype.clear = function () {
  var node = this.element_;
  while (node.hasChildNodes())
    node.removeChild(node.firstChild);
  this.entries_ = [];
};

TestPanel.prototype.setData = function (value) {
  this.data_ = value;
};

TestPanel.prototype.decorate = function () {
  var elm = this.element_;
  elm.className += ' test-panel';
  var self = this;
  elm.onscroll = function (event) { self.onScroll(event); };
  this.element_ = elm;
};

TestPanel.prototype.onScroll = function (event) {
  var elm = this.element_;
  var remaining = elm.scrollHeight - elm.scrollTop - elm.clientHeight;
  if (remaining < 100) {
    this.targetCount_ = this.entries_.length + kTestListAppendSize;
    this.addPendingEntries();
  }
};

TestPanel.prototype.element = function () {
  return this.element_;
};

TestPanel.prototype.addPendingEntries = function () {
  var end = Math.min(this.targetCount_, this.data_.size());
  for (var i = this.entries_.length; i < end; i++) {
    var entry = new TestPanelEntry(this, i);
    entry.appendTo(this.element_);
    this.entries_.push(entry);
  }
};

function TestPanelEntry(panel, serial) {
  this.panel_ = panel;
  this.serial_ = serial;
  this.isOpen_ = false;
  this.details_ = null;
  this.create();
}

TestPanelEntry.NONE = 'none';
TestPanelEntry.FAILED = 'failed';
TestPanelEntry.BLACKLISTED = 'blacklisted';

TestPanelEntry.prototype.getData = function () {
  return this.panel_.data_.getEntry(this.serial_);
}

TestPanelEntry.prototype.create = function () {
  var elm = document.createElement('div');
  elm.className = 'test-panel-entry';

  var header = document.createElement('div');
  header.className = 'test-panel-entry-header';
  var self = this;
  header.onclick = function () { self.onClick() };
  elm.appendChild(header);

  var status = document.createElement('div');
  status.className = 'test-panel-entry-status test-panel-entry-status-none';
  header.appendChild(status);
  var title = document.createElement('div');
  title.className = 'test-panel-entry-text loading';
  header.appendChild(title);
  title.innerHTML = "Loading...";
  this.element_ = elm;
  this.getData().onValue(this, function (test) {
    title.className = 'test-panel-entry-text';
    title.innerHTML = test.getName() + " <span class='description'> - " + test.getDescription() + "</span>";
    status.className = 'test-panel-entry-status test-panel-entry-status-' + test.getStatus();
  });
};

TestPanelEntry.prototype.ensureDetails = function () {
  if (this.details_) return;
  this.details_ = document.createElement('table');
  this.details_.className = 'test-panel-details';
  var row = this.details_.insertRow(0);
  var status = row.insertCell(0);
  status.className = 'test-panel-entry-details-status loading';
  // What fun, to have to do crap like this.  Grr.
  var expander = document.createElement('div');
  expander.style.width = '8px';
  status.appendChild(expander);
  var source = row.insertCell(1);
  source.className = 'test-panel-source';
  var sourceDiv = document.createElement('pre');
  sourceDiv.className = 'source prettyprint lang-js';
  source.appendChild(sourceDiv);
  this.getData().onValue(this, function (test) {
    var text = test.getSource();
    sourceDiv.innerHTML = text.replace(/[\n\r\f]/g, '<br/>');
    status.className = 'test-panel-entry-details-status test-panel-entry-status-' + test.getStatus();
    delay().onValue(this, function () {
      prettyPrint();
    });
  });
};

TestPanelEntry.prototype.showDetails = function () {
  this.ensureDetails();
  this.element_.appendChild(this.details_);
};

TestPanelEntry.prototype.hideDetails = function () {
  this.element_.removeChild(this.details_);
};

TestPanelEntry.prototype.onClick = function () {
  this.getData().onValue(this, function (test) {
    if (this.isOpen_) {
      this.hideDetails();
    } else {
      this.showDetails();
    }
    this.isOpen_ = !this.isOpen_;
  });
};

TestPanelEntry.prototype.appendTo = function (elm) {
  elm.appendChild(this.element_);
};

function ProgressBar(outer, label) {
  this.outer_ = outer;
  this.label_ = label;
  this.control_ = new goog.ui.ProgressBar();
  this.control_.decorate(this.outer_);
}

ProgressBar.prototype.setValue = function (value) {
  this.control_.setValue(value);
  this.setText(value + '%');
};

ProgressBar.prototype.setText = function (value) {
  this.label_.innerHTML = value;
};

function TestControls(start, reset, isContinuation) {
  this.reset_ = reset;
  this.start_ = start;
  this.isContinuation_ = isContinuation;
  this.startState_ = TestControls.STOPPED;
  this.resetState_ = isContinuation ? TestControls.CLEAR : TestControls.NONE;
};

TestControls.STOPPED = 'stopped';
TestControls.RUNNING = 'running';
TestControls.DONE = 'done';
TestControls.CLEAR = 'clear';
TestControls.NONE = 'none';

TestControls.prototype.initialize = function () {
  if (this.resetState_ == TestControls.NONE)
    this.reset_.setEnabled(false);
  if (this.isContinuation_)
    this.start_.setCaption("Resume");
};

TestControls.prototype.startClicked = function (event) {
  var displayResults = event.ctrlKey;
  if (this.startState_ == TestControls.STOPPED) {
    this.startState_ = TestControls.RUNNING;
    this.startTests(displayResults);
  } else if (this.startState_ == TestControls.RUNNING) {
    this.startState_ = TestControls.STOPPED;
    this.pauseTests();
  }
};

TestControls.prototype.startTests = function (displayResults) {
  this.start_.setCaption("Pause");
  this.reset_.setEnabled(false);
  testRun.displayResults_ = displayResults;
  testRun.resume();
};

TestControls.prototype.pauseTests = function () {
  this.start_.setCaption("Resume");
  this.reset_.setEnabled(true);
  testRun.pause();
};

TestControls.prototype.resetClicked = function () {
  this.resetState_ = TestControls.NONE;
  this.reset_.setEnabled(false);
  this.start_.setCaption("Start");
  this.start_.setEnabled(true);
  this.clear();
};

TestControls.prototype.clear = function () {
  testRun = new TestRun(testSuite, progressBar);
  testOutput.clear();
  testRun.setTestList(testOutput);
  testOutput.setData(testRun.getResultData());
  storedTestStatus.clear();
  storedBlacklist.clear();
  testRun.updateUi();
};

TestControls.prototype.allDone = function () {
  this.startState_ = TestControls.STOPPED;
  this.resetState_ = TestControls.CLEAR;
  this.start_.setCaption("Done");
  this.start_.setEnabled(false);
  this.reset_.setEnabled(true);
  storedTestRunning.clear();
};

function movingOn() {
  storedTestRunning.clear();
}

function getUrlParameters() {
  var url = String(window.location.href);
  var qIndex = url.indexOf('?');
  var result = {};
  if (qIndex != -1) {
    var params = url.substring(qIndex + 1);
    var pairs = params.split('&');
    for (var i = 0; i < pairs.length; i++) {
      var pair = pairs[i].split('=');
      result[pair[0]] = pair[1];
    }
  }
  return result;
}

var testSuite;
var testOutput;
var progressBar;
var testRun;
var testControls;
function loaded() {
  blacklist.initialize();
  var selectors = ['about', 'run', 'compare'];
  var bevel = 10;
  for (var i = 0; i < selectors.length; i++) {
    (function () { // I really need an inner scope here!
      var id = selectors[i];
      var elm = goog.dom.getElement(id);
      var panel = goog.ui.RoundedPanel.create(bevel, 1, '#cccccc', '#ffffff', 15);
      elm.onclick = function () { window.location = '/' + id };
      panel.decorate(elm);
    })();
  }
  var mainPanel = goog.ui.RoundedPanel.create(bevel, 1, '#cccccc', '#ffffff', 15);
  mainPanel.decorate(goog.dom.getElement('contents'));
  var suite = new TestQuery(defaultTestSuite);
  testSuite = suite;
  var runcontrols = gebi('runcontrols');
  if (runcontrols) {
    var bar = new ProgressBar(runcontrols, gebi('progress'));
    progressBar = bar;
    bar.setValue(0);
    testRun = new TestRun(suite, bar);
  }
  var testlist = gebi('testlist');
  var isContinuation = false;
  var storedStatus = storedTestStatus.get();
  if (testlist) {
    var data;
    if (testRun) {
      data = testRun.getResultData();
    } else {
      data = suite;
    }
    testOutput = new TestPanel(data, testlist);
    testOutput.addPendingEntries();
    if (testRun) {
      testRun.setTestList(testOutput);
      var storedStatus = storedTestStatus.get();
      if (storedStatus) {
        testRun.fastForward(storedStatus);
        if (testRun.current_ < suite.getSize()) {
          isContinuation = true;
        } else {
          completeStoredResults = storedStatus;
        }
      }
    }
  }
  var startElement = gebi('button');
  if (startElement) {
    var resetElement = gebi('resetbutton');
    var start = goog.ui.decorate(startElement);
    var reset = goog.ui.decorate(resetElement);
    var control = new TestControls(start, reset, isContinuation);
    testControls = control;
    control.initialize();
    start.getElement().onclick =  function (e) {
      control.startClicked(e || window.event);
    };
    reset.getElement().onclick = function (e) {
      control.resetClicked(e || window.event);
    };
  }
  var plotBox = gebi('plotBox');
  if (plotBox) {
    var plotter = new Plotter(results);
    plotter.placeFixpoints();
    plotter.displayOn(plotBox);
  }
}
