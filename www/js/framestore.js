function FrameStore(prog, options) {
  this.prog = prog;
  this.opt = $.extend({}, {}, options);

  this.perSprite = this.prog.spriteSize.width * this.prog.spriteSize.height;
  this.zoomLevels = prog.zoomLevels.sort(function(a, b) {
    return a < b ? 1 : a > b ? -1 : 0;
  });

  // Cache indexed by zoom level, sprite number
  this.cache = {};
}

$.extend(FrameStore.prototype, (function() {
  function quantizeZoom(zoom, zoomLevels) {
    for (var i = 0; i < zoomLevels.length; i++) {
      if (zoomLevels[i] <= zoom) return zoomLevels[i];
    }
    return null;
  }

  function pad(n, width) {
    var out = "" + n;
    while (out.length < width)
      out = "0" + out;
    return out;
  }

  return {
    getSpriteIndex: function(frame, zoom) {
      return Math.floor(frame / zoom / this.perSprite);
    },

    getTileSize: function() {
      return this.prog.tileSize;
    },

    getStripSize: function() {
      return {
        width: this.prog.frames * this.prog.tileSize.width,
        height: this.prog.tileSize.height
      };
    },

    getFrameSpec: function(img, frame, zoom) {
      var prog = this.prog;
      var sprite = this.getSpriteIndex(frame, zoom);
      var index = Math.floor(frame / zoom) - (sprite * this.perSprite);

      return $.extend({}, this.prog.tileSize, {
        frame: frame,
        zoom: zoom,
        sprite: sprite,
        index: index,
        x: (index % prog.spriteSize.width) * prog.tileSize.width,
        y: Math.floor(index / prog.spriteSize.width) * prog.tileSize
          .height
      });
    },

    getFrame: function(frame, zoom) {
      var self = this;
      var loaded = $.Deferred();

      if (zoom < 1 || frame < 0 || frame >= this.prog.frames) {
        loaded.reject( /*error*/ );
        return loaded.promise();
      }

      // Check for cached image we can use.
      for (var i = 0; i < this.zoomLevels.length; i++) {
        var zl = this.zoomLevels[i];
        if (Math.floor(frame / zl) * zl !== frame) continue;
        var idx = this.getSpriteIndex(frame, zl);
        if (this.cache[zl] && this.cache[zl][idx] && this.cache[zl][idx]
          .loaded) {
          var ci = this.cache[zl][idx];
          loaded.resolve(ci.img, this.getFrameSpec(ci.img, frame, zl));
          return loaded.promise();
        }
      }

      // Need to load the image
      var realZoom = quantizeZoom(zoom, this.zoomLevels);
      var sprite = this.getSpriteIndex(frame, realZoom);

      if (!this.cache.hasOwnProperty(realZoom))
        this.cache[realZoom] = {};

      if (!this.cache[realZoom].hasOwnProperty(sprite)) {
        // Need to load the image
        var $img = $("<img></img>");

        var slot = {
          img: $img[0],
          pending: [],
          loaded: false
        };

        $img.load(function() {
          console.log("Loaded...");
          slot.loaded = true;
          for (var j = 0; j < slot.pending.length; j++)
            slot.pending[j]();
          slot.pending = [];
        });

        this.cache[realZoom][sprite] = slot;

        var url = this.prog.sprites + "/x" + realZoom + "/s" + pad(
          sprite, 4) + ".jpg";
        console.log("Loading " + url);
        $img.attr({
          src: url
        });
      }

      this.cache[realZoom][sprite].pending.push(
        function() {
          var ci = self.cache[realZoom][sprite];
          loaded.resolve(ci.img, self.getFrameSpec(ci.img, frame,
            realZoom));
        }
      );

      return loaded.promise();
    }
  };
})());
