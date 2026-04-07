# PowerQuery: CCGI Student File

## Overview

This PowerQuery was created to extract student data from PowerSchool SIS in order to generate a file compatible with CaliforniaColleges.edu (CCGI) student data requirements.

It pulls student demographic, GPA, and program participation data, then exposes it through the PowerSchool API.

---

## What is a PowerQuery?

A **PowerQuery** in PowerSchool is:

> A reusable SQL-based data source that can be accessed via API or internal tools.

It allows you to:
- run complex SQL queries
- expose results as structured data
- integrate PowerSchool with external systems

PowerQueries are commonly used for:
- reporting
- integrations (like this CCGI export)
- automation workflows

## Why is a `plugin.xml` required?

PowerQueries are packaged inside a **PowerSchool plugin**.

The `plugin.xml` file:
- registers the plugin with PowerSchool
- defines permissions and data access
- controls API access

Without `plugin.xml`, PowerSchool:
- will not install the query
- will not allow API access
- will not grant table/field permissions

## Why is `<oauth>` included?

```xml
<oauth></oauth>
This enables OAuth API access for the plugin.
- PowerSchool generates a Client ID and Client Secret
- These are used to authenticate external API callss