# sonarqube-extractor

## Current state

WIP / POC


## About

Simple scripts to extract issues and rules from Sonarqube for easier reporting and controlling.

For issues:
CSV-files can be opened via Excel - makes use of Hyperlink-functionality for easier navagation to issues.

For rules:
Markdown is used for pretty and easy formatting.


## Dependencies

- bash
- curl
- jq


## TODOs

- Refactoring
- Add tests (e.g. via docker setup)
- Migrate to sh (?)
- Provide setup script for dependencies
- Improve password handling, test for params and its values