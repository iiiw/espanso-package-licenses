# espanso-package-licenses

License text and boilerplate for popular open source licenses.
Generate license text and headers on the fly.


## Usage

Create a LICENSE file at the root of your project. Trigger `:lapa2` to insert:

```
    Apache License
    Version 2.0, January 2004
    http://www.apache.org/licenses/

    TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

    1. Definitions.

    "License" shall mean the terms and conditions for use, reproduction, and distribution
    as defined by Sections 1 through 9 of this document.
    ...
```

To place the header for the Apache License 2.0, trigger `:lhapa2` from the first line of your source file:

```
    Copyright 2021 <owner>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    ...
```


## Triggers and Licenses

The triggers are `:l<ID>` and `:lh<ID>`, for license text and header. The `:lhc<ID>` trigger additionally wraps the header in a C-style block comment.

`ID` is an abbreviation of the [SPDX short identifier](https://spdx.org/licenses/).

The selection of licenses is based on <https://opensource.org/licenses>. They are retrieved from the [SPDX license list data repository](https://github.com/spdx/license-list-data). Please file an issue, if you need other licenses.


| Full Name                                       | SPDX Identifier   | ID   | Trigger (Text) | Trigger (Header)  |
| ---                                             | ---               | ---  | ---            | ---               |
| Apache License 2.0                              | Apache-2.0        | apa2 | :lapa2         | :lhapa2, :lhcapa2 |
| BSD 3-Clause "New" or "Revised" License         | BSD-3-Clause      | bsd3 | :lbsd3         |                   |
| BSD 2-Clause "Simplified" License               | BSD-2-Clause      | bsd2 | :lbsd2         |                   |
| GNU General Public License v3.0 or later        | GPL-3.0-or-later  | gpl3 | :lgpl3         | :lhgpl3, :lhcgpl3 |
| GNU Lesser General Public License v3.0 or later | LGPL-3.0-or-later | lgp3 | :llgp3         |                   |
| MIT License                                     | MIT               | mit  | :lmit          |                   |
| Mozilla Public License 2.0                      | MPL-2.0           | mpl2 | :lmpl2         | :lhmpl2, :lhcmpl2 |
| Common Development and Distribution License 1.1 | CDDL-1.1          | cdd1 | :lcdd1         |                   |
| Eclipse Public License 2.0                      | EPL-2.0           | epl2 | :lepl2         |                   |


## Placeholders

Some licenses use placeholders. The year placeholder is always replaced by the current year. If the license has an owner placeholder, the cursor is placed before it.

| Placeholder                                           | Substitution                        |
| ---                                                   | ---                                 |
| `<year>`                                              | This year (`%Y` in strftime format) |
| `<owner>`, `<name of author>`, `<copyright holder> …` | Cursor placed here ==>`|<owner>`    |


## Installation

From source repo:

```
espanso install licenses https://github.com/iiiw/espanso-package-licenses --external
```

## Caveats

1. Licenses are downloaded each time. If the connection is down, the expansion silently fails.
2. It takes a few seconds for the cursor to move back to the (owner) placeholder. Do not leave the active window until the cursor has arrived.
3. Not tested on Windows. If [WSL](https://docs.microsoft.com/en-us/windows/wsl/) is installed, the needed tools (curl, sed and fold) should be in place. Feedback welcome.
