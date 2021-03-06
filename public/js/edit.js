$(function() {
  var FRAME_WIDTH = 128;
  var FRAME_HEIGHT = 72;
  var MIN_ZOOM = 1;
  var MAX_ZOOM = 16384;
  var GAP = 120;

  function buildInterface(programme) {
    var zoomLevels = programme.zoom_levels.split(",")
      .map(function(x) {
        return parseInt(x, 10)
      });
    var prog = {
      sprites: "/asset/sprites/" + programme.redux_reference,
      spriteSize: {
        width: 16,
        height: 16
      },
      tileSize: {
        width: FRAME_WIDTH,
        height: FRAME_HEIGHT
      },
      frames: programme.duration * 25 / 1000,
      zoomLevels: zoomLevels
    }

    var frameStore = new FrameStore(prog);

    resize();

    var frameStripIn = new FrameStrip($(".framestrip-in"), frameStore, {
      kind: "in-point",
      zoom: MAX_ZOOM
    });

    var frameStripOut = new FrameStrip($(".framestrip-out"), frameStore, {
      kind: "out-point",
      zoom: MAX_ZOOM
    });

    $(window)
      .resize(function() {
        resize();
        if (frameStripIn) frameStripIn.redraw();
        if (frameStripOut) frameStripOut.redraw();
      });

    function resize() {
      var width = $(window)
        .width();
      $(".framestrip")
        .attr({
          width: width - GAP
        });
    }

    function canSubmit() {
      var in_point = $("input[name='in']")
        .val();
      var out_point = $("input[name='out']")
        .val();
      if (in_point.length && out_point.length)
        $("input[type='submit']")
        .removeAttr("disabled");
      else
        $("input[type='submit']")
        .attr("disabled", "disabled");
    }

    $(".framestrip-in")
      .on("setcurrent", function(ev, time, tc) {
        $("input[name='in']")
          .val(tc);
        canSubmit();
      });

    $(".framestrip-out")
      .on("setcurrent", function(ev, time, tc) {
        $("input[name='out']")
          .val(tc);
        canSubmit();
      });
    if (programme.in !== null)
      frameStripIn.setCurrent(programme.in * 25 / 1000);

    if (programme.out !== null)
      frameStripOut.setCurrent(programme.out * 25 / 1000);

    canSubmit();

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
  }

  function refreshLock() {
    $.post("/lock", {
        redux_reference: STASH.programme.redux_reference
      })
      .done(function(stats) {
        var kind = Object.keys(stats);
        for (var i = 0; i < kind.length; i++) {
          $(".stats .stat." + kind[i])
            .text(stats[kind[i]]);
        }
        console.log(stats);
      });
  }

  if (STASH.programme) {
    buildInterface(STASH.programme);
    refreshLock();
    setInterval(refreshLock, 5000);
  }

});
