var selected = window.location.hash.split('#')[1];
if(selected){
	var element = document.getElementById(selected);
	element.className += " selected";
}
