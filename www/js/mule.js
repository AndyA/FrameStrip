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
  var frameStrip = new FrameStrip($(".framestrip"), frameStore);

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
    frameStrip.setOffset(frameStrip.getOffset() + shift);
  }

  function zoomBy(ratio) {
    frameStrip.setZoom(frameStrip.getZoom() * ratio);
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
