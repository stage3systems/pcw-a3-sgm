function browserSupportsXdStorage() {
  var userAgent = navigator.userAgent.toLowerCase();
  var isSafari = userAgent.indexOf('safari') > -1 && userAgent.indexOf('chrome') < 0;
  return !isSafari;
}

function getToken(xdStorage, callback) {
  if (browserSupportsXdStorage()) {
    xdStorage.getItem('userToken', callback);
  } else {
    callback(null, localStorage.getItem('userToken'));
  }
}

function setToken(xdStorage, jwt) {
  if (browserSupportsXdStorage()) {
    xdStorage.setItem('userToken', jwt);
  } else {
    localStorage.setItem('userToken', jwt);
  }
}
