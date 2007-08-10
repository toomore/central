<script language="JavaScript" type="text/javascript">
<!--
// bbCode control by
// subBlue design
// www.subBlue.com

// Startup variables
var imageTag = false;
var theSelection = false;

// Check for Browser & Platform for PC & IE specific bits
// More details from: http://www.mozilla.org/docs/web-developer/sniffer/browser_type.html
var clientPC = navigator.userAgent.toLowerCase(); // Get client info
var clientVer = parseInt(navigator.appVersion); // Get browser version

var is_ie = ((clientPC.indexOf("msie") != -1) && (clientPC.indexOf("opera") == -1));
var is_nav = ((clientPC.indexOf('mozilla')!=-1) && (clientPC.indexOf('spoofer')==-1)
                && (clientPC.indexOf('compatible') == -1) && (clientPC.indexOf('opera')==-1)
                && (clientPC.indexOf('webtv')==-1) && (clientPC.indexOf('hotjava')==-1));
var is_moz = 0;

var is_win = ((clientPC.indexOf("win")!=-1) || (clientPC.indexOf("16bit") != -1));
var is_mac = (clientPC.indexOf("mac")!=-1);

// Helpline messages
b_help = "{L_BBCODE_B_HELP}";
i_help = "{L_BBCODE_I_HELP}";
u_help = "{L_BBCODE_U_HELP}";
q_help = "{L_BBCODE_Q_HELP}";
c_help = "{L_BBCODE_C_HELP}";
l_help = "{L_BBCODE_L_HELP}";
o_help = "{L_BBCODE_O_HELP}";
p_help = "{L_BBCODE_P_HELP}";
w_help = "{L_BBCODE_W_HELP}";
a_help = "{L_BBCODE_A_HELP}";
s_help = "{L_BBCODE_S_HELP}";
f_help = "{L_BBCODE_F_HELP}";

// Define the bbCode tags
bbcode = new Array();
bbtags = new Array('[b]','[/b]','[i]','[/i]','[u]','[/u]','[quote]','[/quote]','[code]','[/code]','[list]','[/list]','[list=]','[/list]','[img]','[/img]','[url]','[/url]');
imageTag = false;

// Shows the help messages in the helpline window
function helpline(help) {
	document.post.helpbox.value = eval(help + "_help");
}


// Replacement for arrayname.length property
function getarraysize(thearray) {
	for (i = 0; i < thearray.length; i++) {
		if ((thearray[i] == "undefined") || (thearray[i] == "") || (thearray[i] == null))
			return i;
		}
	return thearray.length;
}

// Replacement for arrayname.push(value) not implemented in IE until version 5.5
// Appends element to the array
function arraypush(thearray,value) {
	thearray[ getarraysize(thearray) ] = value;
}

// Replacement for arrayname.pop() not implemented in IE until version 5.5
// Removes and returns the last element of an array
function arraypop(thearray) {
	thearraysize = getarraysize(thearray);
	retval = thearray[thearraysize - 1];
	delete thearray[thearraysize - 1];
	return retval;
}


function checkForm() {

	formErrors = false;    

	if (document.post.message.value.length < 2) {
		formErrors = "{L_EMPTY_MESSAGE}";
	}

	if (formErrors) {
		alert(formErrors);
		return false;
	} else {
		bbstyle(-1);
		//formObj.preview.disabled = true;
		//formObj.submit.disabled = true;
		return true;
	}
}

/*function emoticon(text) {
	var txtarea = document.post.message;
	text = ' ' + text + ' ';
	if (txtarea.createTextRange && txtarea.caretPos) {
		var caretPos = txtarea.caretPos;
		caretPos.text = caretPos.text.charAt(caretPos.text.length - 1) == ' ' ? caretPos.text + text + ' ' : caretPos.text + text;
		txtarea.focus();
	} else {
		txtarea.value  += text;
		txtarea.focus();
	}
}*/

function emoticon(text) {
  insertAtCaret(document.post.message, text);
}

function insertAtCaret(obj, text) {	if(document.selection) {		obj.focus();		var orig = obj.value.replace(/\r\n/g, "\n");		var range = document.selection.createRange();		if(range.parentElement() != obj) {			return false;		}		range.text = text;				var actual = tmp = obj.value.replace(/\r\n/g, "\n");		for(var diff = 0; diff < orig.length; diff++) {			if(orig.charAt(diff) != actual.charAt(diff)) break;		}		for(var index = 0, start = 0; 			tmp.match(text) 				&& (tmp = tmp.replace(text, "")) 				&& index <= diff; 			index = start + text.length		) {			start = actual.indexOf(text, index);		}	} else if(obj.selectionStart) {		var start = obj.selectionStart;		var end   = obj.selectionEnd;		obj.value = obj.value.substr(0, start) 			+ text 			+ obj.value.substr(end, obj.value.length);	}		if(start != null) {		setCaretTo(obj, start + text.length);	} else {		obj.value += text;	}}function setCaretTo(obj, pos) {	if(obj.createTextRange) {		var range = obj.createTextRange();		range.move('character', pos);		range.select();	} else if(obj.selectionStart) {		obj.focus();		obj.setSelectionRange(pos, pos);	}}

function bbfontstyle(bbopen, bbclose) {
	var txtarea = document.post.message;

	if ((clientVer >= 4) && is_ie && is_win) {
		theSelection = document.selection.createRange().text;
		if (!theSelection) {
			txtarea.value += bbopen + bbclose;
			txtarea.focus();
			return;
		}
		document.selection.createRange().text = bbopen + theSelection + bbclose;
		txtarea.focus();
		return;
	}
	else if (txtarea.selectionEnd && (txtarea.selectionEnd - txtarea.selectionStart > 0))
	{
		mozWrap(txtarea, bbopen, bbclose);
		return;
	}
	else
	{
		txtarea.value += bbopen + bbclose;
		txtarea.focus();
	}
	storeCaret(txtarea);
}


function bbstyle(bbnumber) {
	var txtarea = document.post.message;

	txtarea.focus();
	donotinsert = false;
	theSelection = false;
	bblast = 0;

	if (bbnumber == -1) { // Close all open tags & default button names
		while (bbcode[0]) {
			butnumber = arraypop(bbcode) - 1;
			txtarea.value += bbtags[butnumber + 1];
			buttext = eval('document.post.addbbcode' + butnumber + '.value');
			eval('document.post.addbbcode' + butnumber + '.value ="' + buttext.substr(0,(buttext.length - 1)) + '"');
		}
		imageTag = false; // All tags are closed including image tags :D
		txtarea.focus();
		return;
	}

	if ((clientVer >= 4) && is_ie && is_win)
	{
		theSelection = document.selection.createRange().text; // Get text selection
		if (theSelection) {
			// Add tags around selection
			document.selection.createRange().text = bbtags[bbnumber] + theSelection + bbtags[bbnumber+1];
			txtarea.focus();
			theSelection = '';
			return;
		}
	}
	else if (txtarea.selectionEnd && (txtarea.selectionEnd - txtarea.selectionStart > 0))
	{
		mozWrap(txtarea, bbtags[bbnumber], bbtags[bbnumber+1]);
		return;
	}
	
	// Find last occurance of an open tag the same as the one just clicked
	for (i = 0; i < bbcode.length; i++) {
		if (bbcode[i] == bbnumber+1) {
			bblast = i;
			donotinsert = true;
		}
	}

	if (donotinsert) {		// Close all open tags up to the one just clicked & default button names
		while (bbcode[bblast]) {
				butnumber = arraypop(bbcode) - 1;
				txtarea.value += bbtags[butnumber + 1];
				buttext = eval('document.post.addbbcode' + butnumber + '.value');
				eval('document.post.addbbcode' + butnumber + '.value ="' + buttext.substr(0,(buttext.length - 1)) + '"');
				imageTag = false;
			}
			txtarea.focus();
			return;
	} else { // Open tags
	
		if (imageTag && (bbnumber != 14)) {		// Close image tag before adding another
			txtarea.value += bbtags[15];
			lastValue = arraypop(bbcode) - 1;	// Remove the close image tag from the list
			document.post.addbbcode14.value = "Img";	// Return button back to normal state
			imageTag = false;
		}
		
		// Open tag
		txtarea.value += bbtags[bbnumber];
		if ((bbnumber == 14) && (imageTag == false)) imageTag = 1; // Check to stop additional tags after an unclosed image tag
		arraypush(bbcode,bbnumber+1);
		eval('document.post.addbbcode'+bbnumber+'.value += "*"');
		txtarea.focus();
		return;
	}
	storeCaret(txtarea);
}

// From http://www.massless.org/mozedit/
function mozWrap(txtarea, open, close)
{
	var selLength = txtarea.textLength;
	var selStart = txtarea.selectionStart;
	var selEnd = txtarea.selectionEnd;
	if (selEnd == 1 || selEnd == 2) 
		selEnd = selLength;

	var s1 = (txtarea.value).substring(0,selStart);
	var s2 = (txtarea.value).substring(selStart, selEnd)
	var s3 = (txtarea.value).substring(selEnd, selLength);
	txtarea.value = s1 + open + s2 + close + s3;
	return;
}

// Insert at Claret position. Code from
// http://www.faqts.com/knowledge_base/view.phtml/aid/1052/fid/130
function storeCaret(textEl) {
	if (textEl.createTextRange) textEl.caretPos = document.selection.createRange().duplicate();
}

//-->
</script>

<!-- BEGIN privmsg_extensions -->
<table border="0" cellspacing="0" cellpadding="0" align="center" width="100%">
  <tr> 
	<td valign="top" align="center" width="100%"> 
	  <table height="40" cellspacing="2" cellpadding="2" border="0">
		<tr valign="middle"> 
		  <td>{INBOX_IMG}</td>
		  <td><span class="cattitle">{INBOX_LINK}&nbsp;&nbsp;</span></td>
		  <td>{SENTBOX_IMG}</td>
		  <td><span class="cattitle">{SENTBOX_LINK}&nbsp;&nbsp;</span></td>
		  <td>{OUTBOX_IMG}</td>
		  <td><span class="cattitle">{OUTBOX_LINK}&nbsp;&nbsp;</span></td>
		  <td>{SAVEBOX_IMG}</td>
		  <td><span class="cattitle">{SAVEBOX_LINK}&nbsp;&nbsp;</span></td>
		</tr>
	  </table>
	</td>
  </tr>
</table>

<br clear="all" />
<!-- END privmsg_extensions -->

<form action="{S_POST_ACTION}" method="post" name="post" onsubmit="return checkForm(this)" {S_FORM_ENCTYPE}>

{POST_PREVIEW_BOX}
{ERROR_BOX}
{SEARCHFIRST}

<table width="98%"  border="0" cellspacing="0" cellpadding="0" align="center">
    <td>


<table width="100%"  border="0" cellpadding="0" cellspacing="0" class="border-bleu-jos">
  <tr valign="bottom">
    <td height="26" colspan="3" class="stil01"><table width="100%" height="20"  border="0" cellpadding="0" cellspacing="0" class="border-maro-dr">
      <tr>
        <td width="5%" valign="bottom"><img src="templates/LiteVision/images/05.gif" width="49" height="21"></td>
        <td width="95%" valign="middle">
		<span  class="nav"><a href="{U_INDEX}" class="nav">{L_INDEX}</a>
		<!-- BEGIN switch_not_privmsg --> 
		&raquo; <a href="{U_VIEW_FORUM}" class="nav">{FORUM_NAME}</a></span></td>
		<!-- END switch_not_privmsg -->
<!-- <div align="left">&nbsp;&nbsp; <span class="genmed"><strong>Forum</strong></span></div></td> -->
	
      </tr>
    </table></td>
  </tr>
  <tr>
    <td width="1%" rowspan="2" bgcolor="#D0E4FB" class="border-bleu-st-dr">&nbsp;</td>
    <td width="98%" height="28" valign="bottom" class="stil06">
	
	<table width="99%" height="20"  border="0" align="center" cellpadding="0" cellspacing="0">
      <tr>
        <td><div align="center"><span class="genmed"><strong>{L_POST_A}</strong></span></div></td>
        </tr>
    </table></td>
    <td width="1%" rowspan="2" bgcolor="#D0E4FB" class="border-bleu-st-dr">&nbsp;</td>
  </tr>
    <tr>
    <td bgcolor="#EAF1FC"><table width="99%"  border="0" align="center" cellpadding="0" cellspacing="2">
	<!-- BEGIN switch_username_select -->
      <tr>
        <td width="24%" height="20"><span class="gen"><b>{L_USERNAME}</b></span></td>
        <td width="75%" height="20"><span class="genmed"><input type="text" class="form2" tabindex="1" name="username" size="25" maxlength="25" value="{USERNAME}" /></span></td>
      </tr>
  	<!-- END switch_username_select -->
	<!-- BEGIN switch_privmsg -->
      <tr>
        <td height="20"><span class="gen"><b>{L_USERNAME}</b></span></td>
        <td height="20"><span class="genmed"><input type="text"  class="form2" name="username" maxlength="25" size="25" tabindex="1" value="{USERNAME}" />&nbsp;<input type="submit" name="usersubmit" value="{L_FIND_USERNAME}" class="form2" onclick="window.open('{U_SEARCH_USER}', '_phpbbsearch', 'HEIGHT=250,resizable=yes,WIDTH=400');return false;" /></span></td>
      </tr>
	  	<!-- END switch_privmsg -->
      <tr>
        <td height="20"><span class="gen"><b>{L_SUBJECT}</b></span></td>
        <td height="20"><span class="gen"> 
		<input type="text" name="subject" size="45" maxlength="60" style="width:450px" tabindex="2" class="form2" value="{SUBJECT}" />
		</span></td>
      </tr>
	<!-- BEGIN switch_antibot_post -->
	<tr> 
		<td class="row1"><span class="gen"><b>{L_CONFIRM_POST}</b></span></td>
		<td class="row2"><span class="genmed">
		<select name="confirm_guest_post" size="1">
		    <option value="0">{L_NO}</option>
		    <option value="1">{L_YES}</option>
  		</select>
		{L_CONFIRM_POST_EXPLAIN}</span></td>
	</tr>
	<!-- END switch_antibot_post -->

      <!-- BEGIN topic_description -->

	   <tr>

	     <td class="row1" width="22%"><span class="gen"><b>{L_TOPIC_DESCRIPTION}</b></span></td>

	     <td class="row2" width="78%"><span class="gen">

	      <input type="text" name="topic_desc" size="45" maxlength="60" style="width:450px" tabindex="2" class="post" value="{TOPIC_DESCRIPTION}" />

	      </span></td>

	   </tr>

	  <!-- END topic_description -->
      <tr>
        <td valign="top"><table width="100%" border="0" align="center" cellpadding="1" cellspacing="0">
          <tr>
            <td><span class="gen"><b>{L_MESSAGE_BODY}</b></span> </td>
          </tr>
          <tr>
            <td valign="middle" align="center"> <br />
                <table width="90%" border="0" cellspacing="0" cellpadding="5" class="border-bleu">
                  <tr align="center">
                    <td colspan="{S_SMILIES_COLSPAN}" class="gensmall"><b>{L_EMOTICONS}</b></td>
                  </tr>
                  <!-- BEGIN smilies_row -->
                  <tr align="center" valign="middle">
                    <!-- BEGIN smilies_col -->
                    <td><a href="javascript:emoticon('{smilies_row.smilies_col.SMILEY_CODE}')"><img src="{smilies_row.smilies_col.SMILEY_IMG}" border="0" alt="{smilies_row.smilies_col.SMILEY_DESC}" title="{smilies_row.smilies_col.SMILEY_DESC}" /></a></td>
                    <!-- END smilies_col -->
                  </tr>
                  <!-- END smilies_row -->
                  <!-- BEGIN switch_smilies_extra -->
                  <tr align="center">
                    <td colspan="{S_SMILIES_COLSPAN}"><span  class="nav"><a href="{U_MORE_SMILIES}" onclick="window.open('{U_MORE_SMILIES}', '_phpbbsmilies', 'HEIGHT=300,resizable=yes,scrollbars=yes,WIDTH=250');return false;" target="_phpbbsmilies" class="nav">{L_MORE_SMILIES}</a></span></td>
                  </tr>
                  <!-- END switch_smilies_extra -->
              </table></td>
          </tr>
        </table></td>
        <td valign="top"><span class="gen">
          <table width="450" border="0" cellspacing="0" cellpadding="2">
            <tr align="center" valign="middle">
              <td><span class="genmed">
                <input type="button" class="form2" accesskey="b" name="addbbcode0" value=" B " style="font-weight:bold; width: 30px" onclick="bbstyle(0)" onmouseover="helpline('b')" />
              </span></td>
              <td><span class="genmed">
                <input type="button" class="form2" accesskey="i" name="addbbcode2" value=" i " style="font-style:italic; width: 30px" onclick="bbstyle(2)" onmouseover="helpline('i')" />
              </span></td>
              <td><span class="genmed">
                <input type="button" class="form2" accesskey="u" name="addbbcode4" value=" u " style="text-decoration: underline; width: 30px" onclick="bbstyle(4)" onmouseover="helpline('u')" />
              </span></td>
              <td><span class="genmed">
                <input type="button" class="form2" accesskey="q" name="addbbcode6" value="Quote" style="width: 50px" onclick="bbstyle(6)" onmouseover="helpline('q')" />
              </span></td>
              <td><span class="genmed">
                <input type="button" class="form2" accesskey="c" name="addbbcode8" value="Code" style="width: 40px" onclick="bbstyle(8)" onmouseover="helpline('c')" />
              </span></td>
              <td><span class="genmed">
                <input type="button" class="form2" accesskey="l" name="addbbcode10" value="List" style="width: 40px" onclick="bbstyle(10)" onmouseover="helpline('l')" />
              </span></td>
              <td><span class="genmed">
                <input type="button" class="form2" accesskey="o" name="addbbcode12" value="List=" style="width: 40px" onclick="bbstyle(12)" onmouseover="helpline('o')" />
              </span></td>
              <td><span class="genmed">
                <input type="button" class="form2" accesskey="p" name="addbbcode14" value="Img" style="width: 40px"  onClick="bbstyle(14)" onmouseover="helpline('p')" />
              </span></td>
              <td><span class="genmed">
                <input type="button" class="form2" accesskey="w" name="addbbcode16" value="URL" style="text-decoration: underline; width: 40px" onclick="bbstyle(16)" onmouseover="helpline('w')" />
              </span></td>
            </tr>
            <tr>
              <td colspan="9">
                <table width="100%" border="0" cellspacing="0" cellpadding="0">
                  <tr>
                    <td><span class="genmed"> &nbsp;{L_FONT_COLOR}:
                          <select name="addbbcode18" onchange="bbfontstyle('[color=' + this.form.addbbcode18.options[this.form.addbbcode18.selectedIndex].value + ']', '[/color]');this.selectedIndex=0;" onMouseOver="helpline('s')">
                            <option style="color:black; background-color: {T_TD_COLOR1}" value="{T_FONTCOLOR1}" class="genmed">{L_COLOR_DEFAULT}</option>
                            <option style="color:darkred; background-color: {T_TD_COLOR1}" value="darkred" class="genmed">{L_COLOR_DARK_RED}</option>
                            <option style="color:red; background-color: {T_TD_COLOR1}" value="red" class="genmed">{L_COLOR_RED}</option>
                            <option style="color:orange; background-color: {T_TD_COLOR1}" value="orange" class="genmed">{L_COLOR_ORANGE}</option>
                            <option style="color:brown; background-color: {T_TD_COLOR1}" value="brown" class="genmed">{L_COLOR_BROWN}</option>
                            <option style="color:yellow; background-color: {T_TD_COLOR1}" value="yellow" class="genmed">{L_COLOR_YELLOW}</option>
                            <option style="color:green; background-color: {T_TD_COLOR1}" value="green" class="genmed">{L_COLOR_GREEN}</option>
                            <option style="color:olive; background-color: {T_TD_COLOR1}" value="olive" class="genmed">{L_COLOR_OLIVE}</option>
                            <option style="color:cyan; background-color: {T_TD_COLOR1}" value="cyan" class="genmed">{L_COLOR_CYAN}</option>
                            <option style="color:blue; background-color: {T_TD_COLOR1}" value="blue" class="genmed">{L_COLOR_BLUE}</option>
                            <option style="color:darkblue; background-color: {T_TD_COLOR1}" value="darkblue" class="genmed">{L_COLOR_DARK_BLUE}</option>
                            <option style="color:indigo; background-color: {T_TD_COLOR1}" value="indigo" class="genmed">{L_COLOR_INDIGO}</option>
                            <option style="color:violet; background-color: {T_TD_COLOR1}" value="violet" class="genmed">{L_COLOR_VIOLET}</option>
                            <option style="color:white; background-color: {T_TD_COLOR1}" value="white" class="genmed">{L_COLOR_WHITE}</option>
                            <option style="color:black; background-color: {T_TD_COLOR1}" value="black" class="genmed">{L_COLOR_BLACK}</option>
                          </select>
&nbsp;{L_FONT_SIZE}:
            <select name="addbbcode20" onchange="bbfontstyle('[size=' + this.form.addbbcode20.options[this.form.addbbcode20.selectedIndex].value + ']', '[/size]')" onMouseOver="helpline('f')">
              <option value="7" class="genmed">{L_FONT_TINY}</option>
              <option value="9" class="genmed">{L_FONT_SMALL}</option>
              <option value="12" selected class="genmed">{L_FONT_NORMAL}</option>
              <option value="18" class="genmed">{L_FONT_LARGE}</option>
              <option  value="24" class="genmed">{L_FONT_HUGE}</option>
            </select>
                    </span></td>
                    <td nowrap="nowrap" align="right"><span class="gensmall"><a href="javascript:bbstyle(-1)" class="genmed" onmouseover="helpline('a')">{L_BBCODE_CLOSE_TAGS}</a></span></td>
                  </tr>
              </table></td>
            </tr>
            <tr>
              <td colspan="9"> <span class="gensmall">
                <input type="text" name="helpbox" size="45" maxlength="100" style="width:450px; font-size:10px" class="helpline" value="{L_STYLES_TIP}" />
              </span></td>
            </tr>
            <tr>
              <td colspan="9">
                <textarea name="message" rows="15" cols="35" wrap="virtual" style="width:450px" tabindex="3" class="form2" onselect="storeCaret(this);" onclick="storeCaret(this);" onkeyup="storeCaret(this);">{MESSAGE}</textarea>
              </td>
            </tr>
          </table>
        </span></td>
      </tr>
      <tr>
        <td valign="top"><span class="gen"><b>{L_OPTIONS}</b></span><br /><span class="gensmall">{HTML_STATUS}<br />{BBCODE_STATUS}<br />{SMILIES_STATUS}</span></td>
        <td valign="top"><table cellspacing="0" cellpadding="1" border="0">
          <!-- BEGIN switch_html_checkbox -->
          <tr>
            <td>
              <input type="checkbox" name="disable_html" {S_HTML_CHECKED} />
            </td>
            <td><span class="gen">{L_DISABLE_HTML}</span></td>
          </tr>
          <!-- END switch_html_checkbox -->
          <!-- BEGIN switch_bbcode_checkbox -->
          <tr>
            <td>
              <input type="checkbox" name="disable_bbcode" {S_BBCODE_CHECKED} />
            </td>
            <td><span class="gen">{L_DISABLE_BBCODE}</span></td>
          </tr>
          <!-- END switch_bbcode_checkbox -->
          <!-- BEGIN switch_smilies_checkbox -->
          <tr>
            <td>
              <input type="checkbox" name="disable_smilies" {S_SMILIES_CHECKED} />
            </td>
            <td><span class="gen">{L_DISABLE_SMILIES}</span></td>
          </tr>
          <!-- END switch_smilies_checkbox -->
          <!-- BEGIN switch_signature_checkbox -->
          <tr>
            <td>
              <input type="checkbox" name="attach_sig" {S_SIGNATURE_CHECKED} />
            </td>
            <td><span class="gen">{L_ATTACH_SIGNATURE}</span></td>
          </tr>
          <!-- END switch_signature_checkbox -->
          <!-- BEGIN switch_notify_checkbox -->
          <tr>
            <td>
              <input type="checkbox" name="notify" {S_NOTIFY_CHECKED} />
            </td>
            <td><span class="gen">{L_NOTIFY_ON_REPLY}</span></td>
          </tr>
          <!-- END switch_notify_checkbox -->
          <!-- BEGIN switch_delete_checkbox -->
          <tr>
            <td>
              <input type="checkbox" name="delete" />
            </td>
            <td><span class="gen">{L_DELETE_POST}</span></td>
          </tr>
          <!-- END switch_delete_checkbox -->
          <!-- BEGIN switch_type_toggle -->
          <tr>
            <td></td>
            <td><span class="gen">{S_TYPE_TOGGLE}</span></td>
          </tr>
          <!-- END switch_type_toggle -->
        </table></td>
      </tr>
	{ATTACHBOX}
	{POLLBOX} 
	<!-- Visual Confirmation -->
	<!-- BEGIN switch_confirm -->
	<tr>
		<td class="row1" colspan="2" align="center"><span class="gensmall">{L_CONFIRM_CODE_IMPAIRED}</span><br /><br />{CONFIRM_IMG}<br /><br /></td>
	</tr>
	<tr> 
	  <td class="row1"><span class="gen">{L_CONFIRM_CODE}: * </span><br /><span class="gensmall">{L_CONFIRM_CODE_EXPLAIN}</span></td>
	  <td class="row2"><input type="text" class="post" style="width: 200px" name="confirm_code" size="6" maxlength="6" value="" /></td>
	</tr>
	<!-- END switch_confirm -->
	<tr> 
        <td colspan="2" valign="top"> <div align="center">{S_HIDDEN_FORM_FIELDS}
	<b style='color: #f88; font-size: 12px;'>注意: 非相關主題的商業廣告一律刪除</b><br/>
              <input type="submit" tabindex="5" name="preview" class="form2" value="{L_PREVIEW}" />
            &nbsp;
              <input type="submit" accesskey="s" tabindex="6" name="post" class="form2" value="{L_SUBMIT}" />
        </div></td>
        </tr>
    </table></td>
  </tr>
</table>

</form>
