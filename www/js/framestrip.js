function FrameStrip(canvas, store, options) {
  this.canvas = canvas;
  this.store = store;
  this.opt = $.extend({}, {
    kind: "in-point",
    zoom: 1,
    offset: 0,
    current: null,
    frameTime: 1 / 25
  }, options);
  this.hover = null;
  this.init();
  console.log(this.opt);
}

$.extend(FrameStrip.prototype, (function() {
  var FRAME_WIDTH = 128;
  var FRAME_HEIGHT = 72;
  var MIN_ZOOM = 1;
  var MAX_ZOOM = 4096;
  var FPS = 25;

  function quantize(x, q) {
    return Math.round(x / q) * q;
  }

  function pad(n, width) {
    var out = "" + n;
    while (out.length < width)
      out = "0" + out;
    return out;
  }

  function timecode(tm) {
    var d = [FPS, 60, 60, 99];
    var p = [];
    tm *= FPS;
    for (var i = 0; i < d.length; i++) {
      p.unshift(pad(Math.floor(tm % d[i]), 2));
      tm = Math.floor(tm / d[i]);
    }
    return p.join(":");
  }

  function getPos(cvs, x, y) {
    var rect = cvs.getBoundingClientRect();
    return {
      x: (x - rect.left) * cvs.width / rect.width,
      y: (y - rect.top) * cvs.height / rect.height
    }
  }

  // Mouse tracker for canvas
  function makeTracker($cvs, cb) {
    var cvs = $cvs[0];
    var isDown = false;
    var isDrag = false;
    var posDown = null;

    $cvs.on('mousemove', function(ev) {
        var msg = {
          kind: isDown ? "drag" : "hover",
          pos: getPos(cvs, ev.clientX, ev.clientY)
        };

        if (isDown) {
          msg.posDown = posDown;
          isDrag = true;
        }

        cb(msg);
      })
      .on('mouseenter', function(ev) {
        cb({
          kind: "enter"
        });
      })
      .on('mouseleave', function(ev) {
        cb({
          kind: "leave"
        });
      })
      .on('mousedown', function(ev) {
        if (!isDown) {
          isDown = true;
          posDown = getPos(cvs, ev.clientX, ev.clientY);
        }
      });

    $(window)
      .on('mouseup', function(ev) {
        if (isDown) {
          cb({
            kind: isDrag ? "drop" : "click",
            pos: getPos(cvs, ev.clientX, ev.clientY),
            posDown: posDown
          });
        }

        isDown = false;
        isDrag = false;
        posDown = null;
      });
  }

  function describeEvent(ev) {
    var msg = ["event: " + ev.kind];

    if (ev.pos)
      msg.push(" pos: [" + ev.pos.x + ", " + ev.pos.y + "]");

    if (ev.posDown)
      msg.push(" posDown: [" + ev.posDown.x + ", " + ev.posDown.y + "]");

    return msg.join(", ");
  }

  return {
    init: function() {

      var self = this;
      var lastDrag = null;

      makeTracker(this.canvas, function(ev) {
        //        console.log(describeEvent(ev));
        switch (ev.kind) {
          case "drag":
            var ld = lastDrag || ev.posDown;
            var dx = ev.pos.x - ld.x;
            self.setOffset(self.getOffset() - dx);
            lastDrag = ev.pos;
            break;
          case "drop":
            lastDrag = null;
            break;
          case "hover":
            var frame = self.offsetToFrame(ev.pos.x + self.opt.offset);
            if (self.hover !== frame) {
              self.hover = frame;
              self.redraw();
            }
            break;
          case "leave":
            self.hover = null;
            self.redraw();
            break;
          case "click":
            self.setCurrent(self.offsetToFrame(ev.pos.x + self.opt.offset));
            break;
        }
      });

      this.redraw();
    },

    setCurrent: function(frame) {
      var time = this.frameToTime(frame);
      var tc = timecode(time);
      console.log(tc + ", " + time);
      if (this.opt.current !== frame) {
        this.opt.current = frame;
        this.redraw();
      }
    },

    getCurrent: function() {
      return this.opt.current;
    },

    offsetToFrame: function(offset) {
      var size = this.store.getTileSize();
      return Math.floor(offset / size.width) * this.opt.zoom;
    },

    frameToTime: function(frame) {
      return frame * this.opt.frameTime;
    },

    getCurrentTime: function() {
      return this.frameToTime(this.getCurrent());
    },

    redraw: function() {
      var self = this;
      var cvs = this.canvas[0];
      var ctx = cvs.getContext("2d");

      var stripWidth =
        Math.floor((cvs.width + FRAME_WIDTH) / FRAME_WIDTH);
      var first = Math.floor(this.opt.offset / FRAME_WIDTH);
      var shift = this.opt.offset % FRAME_WIDTH;

      function drawCursor(pos, spec, inset) {
        ctx.beginPath();
        var serif = spec.width / 8;
        switch (self.opt.kind) {
          case "in-point":
            ctx.moveTo(pos + inset + serif, inset);
            ctx.lineTo(pos + inset, inset);
            ctx.lineTo(pos + inset, spec.height - 1 - inset);
            ctx.lineTo(pos + inset + serif, spec.height - 1 - inset);
            break;
          case "out-point":
            ctx.moveTo(pos - inset + spec.width - 1 - serif, inset);
            ctx.lineTo(pos - inset + spec.width - 1, inset);
            ctx.lineTo(pos - inset + spec.width - 1, spec.height - 1 -
              inset);
            ctx.lineTo(pos - inset + spec.width - 1 - serif, spec.height -
              1 - inset);
            break;
        }
      }

      for (var f = 0; f < stripWidth; f++) {
        (function(frame, pos) {
          self.store.getFrame(frame, self.opt.zoom)
            .done(function(img, spec) {
              var hpos = pos * spec.width - shift;
              ctx.save();
              ctx.fillStyle = "black";
              ctx.fillRect(hpos, 0, spec.width, cvs.height);

              if (self.opt.current !== null) {
                switch (self.opt.kind) {
                  case "in-point":
                    if (frame < self.opt.current)
                      ctx.globalAlpha = 0.5;
                    break;
                  case "out-point":
                    if (frame > self.opt.current)
                      ctx.globalAlpha = 0.5;
                    break;
                }
              }

              ctx.drawImage(img,
                spec.x, spec.y, spec.width, spec.height,
                hpos, 0, spec.width, spec.height
              );

              ctx.globalAlpha = 1;

              if (frame === self.hover) {
                drawCursor(hpos, spec, 3);
                ctx.lineWidth = 5;
                ctx.strokeStyle = "rgba(100, 100, 100, 0.7)";
                ctx.stroke();
              }

              if (self.opt.current !== null &&
                frame === quantize(self.opt.current, self.opt.zoom)
              ) {
                drawCursor(hpos, spec, 3);
                ctx.lineWidth = 5;
                ctx.strokeStyle = "red";
                ctx.stroke();
              }

              ctx.strokeStyle = "white";
              ctx.lineWidth = 3;
              ctx.beginPath();
              ctx.moveTo(hpos, spec.height);
              ctx.lineTo(hpos, cvs.height);
              ctx.stroke();

              var tc = timecode(self.frameToTime(frame));
              ctx.font = '12px "Lucida Console", Monaco, monospace';
              ctx.fillStyle = "white";
              var m = ctx.measureText(tc);
              ctx.fillText(tc, hpos + (spec.width - m.width) / 2,
                spec.height + 13, spec.width);

              ctx.restore();
            });
        })((f + first) * self.opt.zoom, f);
      }
    },

    maxOffset: function() {
      var size = this.store.getStripSize();
      return size.width / this.opt.zoom - this.canvas[0].width;
    },

    getZoom: function() {
      return this.opt.zoom;
    },

    getOffset: function() {
      return this.opt.offset;
    },

    setZoom: function(zoom) {
      var newZoom = Math.max(MIN_ZOOM, Math.min(zoom, MAX_ZOOM));
      if (newZoom !== this.opt.zoom) {
        var oldZoom = this.opt.zoom;
        //        console.log("zoom:" + newZoom);
        var half = this.canvas[0].width / 2;
        this.opt.zoom = newZoom;
        this.opt.offset = Math.floor(Math.max(0, Math.min((this.opt.offset +
          half) * (oldZoom / newZoom) - half, this.maxOffset())));

        this.redraw();
      }
      return newZoom;
    },

    setOffset: function(offset) {
      var newOffset = Math.max(0, Math.min(offset, this.maxOffset()));
      if (newOffset !== this.opt.offset) {
        //        console.log("offset:" + newOffset);
        this.opt.offset = newOffset;
        this.redraw();
      }
      return newOffset;
    }
  };
})());
