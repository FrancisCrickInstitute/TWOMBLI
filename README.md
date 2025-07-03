[![Image.sc forum](https://img.shields.io/badge/dynamic/json.svg?label=forum&url=https%3A%2F%2Fforum.image.sc%2Ftags%2Ftwombli.json&query=%24.topic_list.tags.0.topic_count&colorB=brightgreen&&suffix=%20topics&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAABPklEQVR42m3SyyqFURTA8Y2BER0TDyExZ+aSPIKUlPIITFzKeQWXwhBlQrmFgUzMMFLKZeguBu5y+//17dP3nc5vuPdee6299gohUYYaDGOyyACq4JmQVoFujOMR77hNfOAGM+hBOQqB9TjHD36xhAa04RCuuXeKOvwHVWIKL9jCK2bRiV284QgL8MwEjAneeo9VNOEaBhzALGtoRy02cIcWhE34jj5YxgW+E5Z4iTPkMYpPLCNY3hdOYEfNbKYdmNngZ1jyEzw7h7AIb3fRTQ95OAZ6yQpGYHMMtOTgouktYwxuXsHgWLLl+4x++Kx1FJrjLTagA77bTPvYgw1rRqY56e+w7GNYsqX6JfPwi7aR+Y5SA+BXtKIRfkfJAYgj14tpOF6+I46c4/cAM3UhM3JxyKsxiOIhH0IO6SH/A1Kb1WBeUjbkAAAAAElFTkSuQmCC)](https://forum.image.sc/tags/twombli) [![Build](https://github.com/FrancisCrickInstitute/TWOMBLI/actions/workflows/release.yml/badge.svg)](https://github.com/FrancisCrickInstitute/TWOMBLI/actions/workflows/release.yml) ![Commit activity](https://img.shields.io/github/commit-activity/y/FrancisCrickInstitute/TWOMBLI?style=plastic) ![GitHub](https://img.shields.io/github/license/FrancisCrickInstitute/TWOMBLI?color=green&style=plastic)

# Overview

![TWOMBLI Overview](https://www.life-science-alliance.org/content/lsa/4/3/e202000880/F3.large.jpg)

TWOMBLI stands for The Workflow Of Matrix BioLogy Informatics. Diverse extracellular matrix (ECM) patterns are observed in both normal and pathological tissue.The aim of TWOMBLI is to quantify matrix patterns. The name TWOMBLI is also a nod to the American artist Cy Twombly whose works are full of diverse marks and patterning. 

TWOMBLI allows the quantificaiton of the following metrics, illustrated below:
* Number of fibre endpoints
* Number of fibre branchpoints
* % of image occupied by high density matrix (HDM)
* Fibre curvature
* Fractal dimension of fibre network

![TWOMBLI Metrics](https://www.life-science-alliance.org/content/lsa/4/3/e202000880/F2.large.jpg)

## Version 1

TWOMBLI was originally published as an ImageJ/FIJI macro:

>Wershof E, Park D, Barry DJ, Jenkins RP, Rullan A, Wilkins A, Schlegelmilch K, Roxanis I, Anderson KI, Bates PA, Sahai E (2021) A FIJI macro for quantifying fibrillar patterns. _Life Science Alliance_, 4 (3) e202000880; DOI: 10.26508/lsa.202000880

However, the ongoing maintance and development of the macro code was proving challenging, particularly as the number of users grew, along with requests for additional features and improved functionality.

## Version 2

TWOMBLI was therefore reimplemented as a FIJI plugin, using software engineering best practices. Aside from easing future maintenance, reimplementing in Java allows the creation of a much more user-friendly interface and simplifies the addition of new functionality.

# Getting Started with TWOMBLI



# Developing TWOMBLI

## Development Setup:
Clone this repository locally, open the project in your IDE of choice, build using maven.

Artifact deployments may be automated in future using github workflows + PRs.

## Production Setup:
Open ImageJ and download the TWOMBLI plugin.

The TWOMBLI Command can then be triggered by navigating to plugins > TWOMBLI.

## Usage:
Either watch the provided video guide () or refer to this repositories 'wiki'.

## Contribution Guidelines:
This repository uses GitHub's built-in issues, pull requests, and workflow tools.
Please conform to the existing repository styles and standards.

To contribute to the documentation, please submit an issue with your desired changes.
To report a bug or feature request please submit an issue here: https://github.com/FrancisCrickInstitute/TWOMBLI/issues
To contribute please submit a pull request here: https://github.com/FrancisCrickInstitute/TWOMBLI/pulls

## Contact Details:
* Image SC forums (https://forum.image.sc/)
* jon.smith@crick.ac.uk
* david.barry@crick.ac.uk
