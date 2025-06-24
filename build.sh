#!/bin/bash
set -e
mkdir -p out/csharp
mkdir -p out/java
mkdir -p out/python
protoc *.proto --csharp_out=out/csharp --java_out=out/java --python_out=out/python
echo Build complete.
