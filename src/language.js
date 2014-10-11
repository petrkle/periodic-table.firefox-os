[% FOREACH loc IN languages %]
var button[% loc.android %] = document.getElementById('btn[% loc.android %]');
button[% loc.android %].addEventListener('click', function(){
	localStorage.setItem('lang', '[% loc.android %]');
	window.location='../index.html';
})
[% END %]
var buttondefault = document.getElementById('btndefault');
buttondefault.addEventListener('click', function(){
	localStorage.removeItem('lang');
	window.location='../index.html';
})
