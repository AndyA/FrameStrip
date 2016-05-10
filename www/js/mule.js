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
    tileSize: {
      width: FRAME_WIDTH,
      height: FRAME_HEIGHT
    },
    frames: 100261,
    zoomLevels: [1, 2, 4, 8, 16, 32, 64, 128, 256]
  }

  var frameStore = new FrameStore(prog);

  var frameStripIn = new FrameStrip($(".framestrip-in"), frameStore, {
    kind: "in-point"
  });

  var frameStripOut = new FrameStrip($(".framestrip-out"), frameStore, {
    kind: "out-point"
  });

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

  function offsetBy(shift) {
    frameStripIn.setOffset(frameStripIn.getOffset() + shift);
    frameStripOut.setOffset(frameStripOut.getOffset() + shift);
  }

  function zoomBy(ratio) {
    frameStripIn.setZoom(frameStripIn.getZoom() * ratio);
    frameStripOut.setZoom(frameStripOut.getZoom() * ratio);
  }

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
