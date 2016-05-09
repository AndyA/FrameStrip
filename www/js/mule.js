$(function() {

  var FRAME_WIDTH = 128;
  var FRAME_HEIGHT = 72;
  var MIN_ZOOM = 1;
  var MAX_ZOOM = 4096;

  var prog = {
    sprites: "/sprites/20020705-013950-kilroy",
    spriteSize: {
      width: 16,
      height: 16
    },
    frames: 100261,
    zoomLevels: [1, 2, 4, 8, 16, 32, 64, 128, 256]
  }

  var fs = new FrameStore(prog);
  var $cvs = $(".strip");
  var cvs = $cvs[0];
  var ctx = cvs.getContext("2d");
  var strip_width = Math.floor((cvs.width + FRAME_WIDTH) / FRAME_WIDTH);

  var zoom = 1;
  var offset = 0;

  function clickKey($elt, hotkey, cb) {
    $elt.click(function(ev) {
      if (!$(this)
        .hasClass("disabled"))
        cb(ev);
      ev.preventDefault();
    });

    if (hotkey) {
      $(document)
        .bind("keydown", hotkey, function(ev) {
          if (!$elt.hasClass("disabled"))
            cb(ev);
          ev.preventDefault();
        });
    }
  }

  function redrawStrip(zoom, offset, width) {
    var first = Math.floor(offset / FRAME_WIDTH);
    var shift = offset % FRAME_WIDTH;

    for (var f = 0; f < width; f++) {
      (function(frame, pos) {
        fs.getFrame(frame, zoom)
          .done(function(img, spec) {
            ctx.drawImage(img,
              spec.x, spec.y, spec.width, spec.height,
              pos * spec.width - shift, 0, spec.width, spec.height
            );
          });
      })((f + first) * zoom, f);
    }
  }

  function maxOffset(zoom) {
    return prog.frames * FRAME_WIDTH / zoom - cvs.width;
  }

  function offsetBy(shift) {
    var noff = Math.max(0, Math.min(offset + shift, maxOffset(zoom)));
    if (noff !== offset) {
      offset = noff;
      redrawStrip(zoom, offset, strip_width);
    }
  }

  function zoomBy(ratio) {
    var nzoom = Math.max(MIN_ZOOM, Math.min(zoom * ratio, MAX_ZOOM));
    if (nzoom !== zoom) {
      var half = cvs.width / 2;
      offset = Math.floor(Math.max(0, Math.min((offset + half) * zoom /
        nzoom - half,
        maxOffset(nzoom))));
      zoom = nzoom;
      redrawStrip(zoom, offset, strip_width);
    }
  }

  redrawStrip(zoom, offset, strip_width);

  clickKey($('.btn.frame-left'), 'left', function(ev) {
    offsetBy(-FRAME_WIDTH / 4);
  });

  clickKey($('.btn.frame-right'), 'right', function(ev) {
    offsetBy(FRAME_WIDTH / 4);
  });


  clickKey($('.btn.frame-jump-left'), 'shift+left', function(ev) {
    offsetBy(-FRAME_WIDTH * 4);
  });

  clickKey($('.btn.frame-jump right'), 'shift+right', function(ev) {
    offsetBy(FRAME_WIDTH * 4);
  });

  clickKey($('.btn.zoom-in'), 'shift+= =', function(ev) {
    zoomBy(0.5);
  });

  clickKey($('.btn.zoom-out'), '-', function(ev) {
    zoomBy(2);
  });

});
