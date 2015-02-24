# Travis script for Bower package auto release, based on new tag detection
VERSION: 0.0.8

# Real project actions

1. Set actual values inside of **"CHANGE THESE VALUE"** block in
`script/release.sh` file. Variables cover:
    
    - git config parameters
    - basic repository local and github name
    - sibling bower repository local and github name
    - deploy key decryption variables and file location
2. Enter commands needed for final bower files building inside of `build()`
function
3. Enter commands for copying files from local base repository to local bower
repository inside of `copy()` function
4. Enter command for replacing version value to current $TRAVIS_TAG value
inside of `replace_verion()` function
5. Replace script call string inside of `.travis.yml`. Example:

```
script:
- 'if [ -n "${TRAVIS_TAG}" ]; then ./script/release.sh; fi'
```
