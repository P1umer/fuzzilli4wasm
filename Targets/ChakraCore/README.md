# [TODO] Target: ChakraCore

To build ChakraCore (ch) for fuzzing:

1. Clone the ChakraCore from https://github.com/microsoft/ChakraCore
2. Apply chakracore.patch. The patch should apply cleanly to git commit 41ad58a9eebf8d52a83424c8fccfaacdb14105ec
3. Run the fuzzbuild.sh script in the ChakraCore root directory
4. FuzzBuild/Debug/ch will be the JavaScript shell for the fuzzer

