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

function loadBrewImages(width, height) {
  if (typeof height == 'undefined') {
    height = 180;
  }

  var $imageDivs = $('.brew-image');
  _.each($imageDivs, function(imageDiv) {
    $imageDiv = $(imageDiv);
    var imageId = $imageDiv.data('image-id');
    if(typeof width == 'undefined') {
      width = $imageDiv.width();
    }
    $imageDiv.prepend($.cloudinary.image(imageId, { height: height, width: width, crop: "fill", gravity: "north" }));
  });

  $('.image-carousel-slider').unslider({
    autoplay: true,
    delay: 3000,
    infinite: true,
    arrows: false,
  });
}
