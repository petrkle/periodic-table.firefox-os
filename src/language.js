[% FOREACH loc IN languages %]
var button[% loc.browser FILTER remove('-') %] = document.getElementById('btn[% loc.browser FILTER remove('-') %]');
button[% loc.browser FILTER remove('-') %].addEventListener('click', function(){
	localStorage.setItem('lang', '[% loc.browser %]');
	window.location='../index.html';
})
[% END %]
var buttondefault = document.getElementById('btndefault');
buttondefault.addEventListener('click', function(){
	localStorage.removeItem('lang');
	window.location='../index.html';
})
