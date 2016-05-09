$(function() {

  var FRAME_WIDTH = 128;
  var FRAME_HEIGHT = 72;

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
  var strip_width = Math.floor((cvs.width + FRAME_WIDTH) / FRAME_WIDTH);

  var zoom = 1024;
  var offset = 0;

  function redrawStrip(zoom, offset, width) {
    var first = Math.floor(offset / FRAME_WIDTH);
    var shift = offset % FRAME_WIDTH;

    for (var f = 0; f < width; f++) {
      (function(frame, pos) {
        fs.getFrame(frame, zoom)
          .done(function(img, spec) {
            var ctx = cvs.getContext("2d");
            ctx.drawImage(img,
              spec.x - shift, spec.y, spec.width, spec.height,
              pos * spec.width, 0, spec.width, spec.height
            );
          });
      })(f * zoom + first, f);
    }
  }

  redrawStrip(zoom, offset, strip_width);
});
