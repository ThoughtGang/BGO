# BGO
Binary Generic Objects: framework for binary analysis


# Purpose

There are many open-source tools available for binary analysis: binutils, 
capstone, elfsh, llvm, metasm, radare, volatility... the list keeps growing.

The BGO project aims to provide a platform for integrating these targeted
tool into a more general-purpose analysis suite. The BGO framework provides
no native loaders, disassemblers, debggers, or tracers; instead, it uses
plugins to invoke external tools and convert their output into BGO's
data model. This allows unrelated analysis tools to be chained together, and
additional plugins can be developed to operate entirely on the BGO 
representation.

Applications such as user interfaces or server-side processes can be built on
top of BGO in order to 

# Features

* scriptable in Ruby
* extensible, plugin-base architecture
* Git-backed projects for version control and distributed collaboration
* JSON serialization
* access to Java classes (and JARs) via jruby 
* "layer"-based representation of memory addresses to accomodate different interpretations of code and data, or changes to code and data over time

# Applications

The BGO framework includes the bgo command line utility, which provides a 
toolchain for binary analysis.

Ream (unreleased) is a Qt4 reverse engineering and refactoring tool built on top
of BGO.

ReWB (unreleased) is a Qt4 UI for BGO.

ReHash (unreleased) is a GitLab-based web application for collaborative
reverse engineering, based on the BGO framework.


# Example

# License
https://github.com/mkfs/pogo-license
This is the standard BSD 3-clause license with a 4th clause added to prohibit 
non-collaborative communication with project developers.
