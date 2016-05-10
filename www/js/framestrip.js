function FrameStrip(canvas, store, options) {
  this.canvas = canvas;
  this.store = store;
  this.opt = $.extend({}, options, {
    kind: "in-point",
    zoom: 1,
    offset: 0
  });
  this.init();
}

$.extend(FrameStrip.prototype, (function() {
  var FRAME_WIDTH = 128;
  var FRAME_HEIGHT = 72;
  var MIN_ZOOM = 1;
  var MAX_ZOOM = 4096;

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
        console.log(describeEvent(ev));
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
        }
      });

      this.redraw();
    },

    drawStrip: function(ctx, zoom, offset, width) {
      var self = this;
      var first = Math.floor(offset / FRAME_WIDTH);
      var shift = offset % FRAME_WIDTH;

      for (var f = 0; f < width; f++) {
        (function(frame, pos) {
          self.store.getFrame(frame, zoom)
            .done(function(img, spec) {
              ctx.drawImage(img,
                spec.x, spec.y, spec.width, spec.height,
                pos * spec.width - shift, 0, spec.width, spec.height
              );
            });
        })((f + first) * zoom, f);
      }
    },

    redraw: function() {
      var cvs = this.canvas[0];
      var stripWidth =
        Math.floor((cvs.width + FRAME_WIDTH) / FRAME_WIDTH);
      this.drawStrip(cvs.getContext("2d"),
        this.opt.zoom, this.opt.offset, stripWidth);
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
        console.log("zoom:" + newZoom);
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
        console.log("offset:" + newOffset);
        this.opt.offset = newOffset;
        this.redraw();
      }
      return newOffset;
    }
  };
})());
