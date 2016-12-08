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

function loadBrewImages() {
  var w = $(window).width();
  var $imageDivs = $('.primary-image');
  _.each($imageDivs, function(imageDiv) {
    $imageDiv = $(imageDiv);
    var imageId = $imageDiv.data('image-id');
    var divWidth = $imageDiv.width();
    $imageDiv.prepend($.cloudinary.image(imageId, { width: divWidth, crop: "fill", gravity: "north" }));
  });
}
