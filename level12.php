<?php
$defaultdata = array( "showpassword"=>"no", "bgcolor"=>"#ffffff");


function xor_encrypt($in, $key) {
    $text = $in;
    $outText = '';

    // Iterate through each character
    for($i=0;$i<strlen($text);$i++) {
    $outText .= $text[$i] ^ $key[$i % strlen($key)];
    }

    return $outText;
}


function get_key($in, $out) {
    $key = '';

    // Iterate through each character
    for($i=0;$i<strlen($in);$i++) {
    	$key .= $in[$i] ^ $out[$i];
    }

    return $key;
}

// $data = loadData($defaultdata);
// print json_encode($defaultdata);
$decoded = base64_decode("HmYkBwozJw4WNyAAFyB1VUcqOE1JZjUIBis7ABdmbU1GIjEJAyIxTRg=");
$xor_result = json_encode($defaultdata);
$key = get_key($xor_result, $decoded);
print "key is $key\n";

print base64_encode(xor_encrypt(json_encode($defaultdata), 'eDWo'));

$expecting =  base64_encode(xor_encrypt(json_encode(array( "showpassword"=>"yes", "bgcolor"=>"#ffffff")),'eDWo'));

print "Expecting: $expecting\n";

$tempdata = json_decode(xor_encrypt(base64_decode($expecting),'eDWo'), true);
print json_encode($tempdata);

if($tempdata["showpassword"] == "yes") {
    print "\nThe password for natas12 is <censored>\n";
}