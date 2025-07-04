[![Image.sc forum](https://img.shields.io/badge/dynamic/json.svg?label=forum&url=https%3A%2F%2Fforum.image.sc%2Ftags%2Ftwombli.json&query=%24.topic_list.tags.0.topic_count&colorB=brightgreen&&suffix=%20topics&logo=data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAABPklEQVR42m3SyyqFURTA8Y2BER0TDyExZ+aSPIKUlPIITFzKeQWXwhBlQrmFgUzMMFLKZeguBu5y+//17dP3nc5vuPdee6299gohUYYaDGOyyACq4JmQVoFujOMR77hNfOAGM+hBOQqB9TjHD36xhAa04RCuuXeKOvwHVWIKL9jCK2bRiV284QgL8MwEjAneeo9VNOEaBhzALGtoRy02cIcWhE34jj5YxgW+E5Z4iTPkMYpPLCNY3hdOYEfNbKYdmNngZ1jyEzw7h7AIb3fRTQ95OAZ6yQpGYHMMtOTgouktYwxuXsHgWLLl+4x++Kx1FJrjLTagA77bTPvYgw1rRqY56e+w7GNYsqX6JfPwi7aR+Y5SA+BXtKIRfkfJAYgj14tpOF6+I46c4/cAM3UhM3JxyKsxiOIhH0IO6SH/A1Kb1WBeUjbkAAAAAElFTkSuQmCC)](https://forum.image.sc/tags/twombli) [![Build](https://github.com/FrancisCrickInstitute/TWOMBLI/actions/workflows/release.yml/badge.svg)](https://github.com/FrancisCrickInstitute/TWOMBLI/actions/workflows/release.yml) ![Commit activity](https://img.shields.io/github/commit-activity/y/FrancisCrickInstitute/TWOMBLI?style=plastic) ![GitHub](https://img.shields.io/github/license/FrancisCrickInstitute/TWOMBLI?color=green&style=plastic)

# Overview

![TWOMBLI Metrics](https://www.life-science-alliance.org/content/lsa/4/3/e202000880/F2.large.jpg)

**TWOMBLI**, which stands for **The Workflow Of Matrix BioLogy Informatics**, is a tool designed to quantify diverse extracellular matrix (ECM) patterns observed in both normal and pathological tissues. The name TWOMBLI also pays homage to the American artist [Cy Twombly](https://en.wikipedia.org/wiki/Cy_Twombly), whose works are renowned for their varied marks and patterning.

TWOMBLI enables the quantification of the following key metrics, illustrated above:
* Number of fibre endpoints
* Number of fibre branchpoints
* Percentage of image occupied by high-density matrix (HDM)
* Fibre curvature
* Fractal dimension of the fibre network

### Version 1: The Original Macro

TWOMBLI was initially released as an ImageJ/FIJI macro:

>Wershof E, Park D, Barry DJ, Jenkins RP, Rullan A, Wilkins A, Schlegelmilch K, Roxanis I, Anderson KI, Bates PA, Sahai E (2021) A FIJI macro for quantifying fibrillar patterns. _Life Science Alliance_, 4 (3) e202000880; DOI: 10.26508/lsa.202000880

However, maintaining and developing this macro became challenging as the user base grew and requests for new features and improved functionality increased.

### Version 2: The Java Plugin for FIJI

To address these challenges, TWOMBLI was **reimplemented as a FIJI plugin**, adhering to best practices in software engineering. This transition to Java not only simplifies future maintenance but also allows for a more user-friendly interface and easier integration of new functionalities.

### Key Differences: Version 1 vs. Version 2

For users, the main distinction between TWOMBLI Version 1 (macro) and Version 2 (Java plugin) is the significantly improved graphical user interface (GUI). While the look and feel are much more user-friendly in Version 2, rest assured that the underlying analysis remains identical. You'll set the exact same parameters and get virtually the same results and data as you did with Version 1.

# Installation

In Fiji, you just need to add the TWOMBLI site to your list of update sites:
1. From the FIJI menu, navigate to `Help` › `Update…` to launch [the updater](https://imagej.net/plugins/updater).
2. Click on `Manage update sites`. This will open a dialog where you can activate additional update sites.
3. Activate the **TWOMBLI** update site and close the dialog.
4. Click `Apply changes` and restart FIJI.

# Getting Started with TWOMBLI

Read the documentation here (_insert link to readthedocs_) to get started.

# Developing TWOMBLI

### Development Setup:
Clone this repository locally, open the project in your IDE of choice, build using maven. Artifact deployments may be automated in future using github workflows + PRs.

### Contribution Guidelines:
This repository uses GitHub's built-in issues, pull requests, and workflow tools. Please conform to the existing repository styles and standards.
* To contribute to the documentation, please submit an issue with your desired changes.
* To report a bug or feature request please submit an issue here: https://github.com/FrancisCrickInstitute/TWOMBLI/issues
* To contribute please submit a pull request here: https://github.com/FrancisCrickInstitute/TWOMBLI/pulls

# Get Help:

The best place to ask for help is the [Image.sc forum](https://forum.image.sc/):
* [Create an account](https://forum.image.sc/signup) if you don't have one already
* [Search to see if someone has already asked a similar question](https://forum.image.sc/tag/twombli) - there may already be a relevant answer
* If not, create a new topic using the #twombli hashtag
