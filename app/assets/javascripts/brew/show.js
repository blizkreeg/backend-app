// Dynamically load profile photo adjusted to the webview w/h
function loadProfilePhotos() {
  width = $(window).width(); //$('.profile-card').width();
  height = $(window).height();
  $('.profile-card-lightbox').each(function() {
    var $card = $(this);
    var imageId = $card.find('.profile-card__photo').data('image-id');
    $card.find('.profile-card__photo img').replaceWith($.cloudinary.image(imageId, { width: width, height: height, crop: 'fill', gravity: 'face' }));
  });
}

function sendProfileViewedEvent(profileObject) {
  var eventCategory = 'Profile';
  var eventAction = 'view';

  ga('send', {
    hitType: 'event',
    eventCategory: eventCategory,
    eventAction: eventAction
  });
}
