function loadTimeCharts() {
  $('.time-remaining-chart').easyPieChart({
    scaleColor: false,
    trackColor: 'rgba(255,0,0,0.1)',
    lineWidth: 4,
    lineCap: 'butt',
    size: 75,
    barColor: '#fd5b63',
    animate: 1000,
  });
}

function loadBrewImages(height = 180) {
  var w = $(window).width();
  var $imageDivs = $('.brew-image');
  _.each($imageDivs, function(imageDiv) {
    $imageDiv = $(imageDiv);
    var imageId = $imageDiv.data('image-id');
    var divWidth = $imageDiv.width();
    $imageDiv.prepend($.cloudinary.image(imageId, { height: height, width: divWidth, crop: "fill", gravity: "north" }));
  });

  $('.image-carousel-slider').unslider({
    autoplay: true,
    delay: 3000,
    infinite: true,
    arrows: false,
  });
}
