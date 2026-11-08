# SPDX-FileCopyrightText: 2026 Nand Compute LLC
# SPDX-License-Identifier: MIT-0

# ===================================================================
# Doxygen documentation project
# Nand Compute Templates — doxygen/
#
# Copy this file and Doxyfile.in into the project's docs/ folder.
# Normally run through "make docs" (mk/doxygen.mk), which passes the
# settings below. To run it by hand:
#   cmake -B build-docs -S docs -DDOC_PROJECT_ROOT=$PWD -DDOC_INPUT=src
#   cmake --build build-docs --target doc
# ===================================================================
cmake_minimum_required(VERSION 3.16)
project(Documentation NONE)

# -------------------------------------------------------------------
# Settings
# -------------------------------------------------------------------
set(DOC_PROJECT_ROOT  ""        CACHE PATH   "Project root; paths in the docs are shown relative to it")
set(DOC_PROJECT_NAME  ""        CACHE STRING "Title shown in the documentation")
set(DOC_PROJECT_BRIEF ""        CACHE STRING "One-line description under the title")
set(DOCVER            "0.0.0"   CACHE STRING "Version shown in the documentation")
set(DOC_INPUT         ""        CACHE STRING "Files and directories to document (;-separated, relative to DOC_PROJECT_ROOT or absolute)")
set(DOC_OUTPUT_DIR    "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Where html/, latex/, the PDF, etc. are written")

option(DOC_GEN_HTML       "Generate HTML"                                      ON)
option(DOC_GEN_PDF        "Generate a PDF (needs pdflatex and make)"           OFF)
option(DOC_GEN_RTF        "Generate RTF"                                       OFF)
option(DOC_GEN_MAN        "Generate man pages"                                 OFF)
option(DOC_EXTRACT_ALL    "Document undocumented code too (hides 'not documented' warnings)" ON)
option(DOC_WARN_AS_ERROR  "Fail the build on any Doxygen warning (for CI)"     OFF)
option(DOC_DISABLE_DOT    "Don't draw graphs even if Graphviz is installed"    OFF)

if(NOT DOC_PROJECT_ROOT)
    message(FATAL_ERROR "Set DOC_PROJECT_ROOT to the project root: -DDOC_PROJECT_ROOT=<path>")
endif()
if(NOT DOC_INPUT)
    message(FATAL_ERROR "Set DOC_INPUT to the files and directories to document: -DDOC_INPUT=<path>;<path>")
endif()
if(NOT DOC_PROJECT_NAME)
    get_filename_component(DOC_PROJECT_NAME "${DOC_PROJECT_ROOT}" NAME)
endif()

# -------------------------------------------------------------------
# Tools
# -------------------------------------------------------------------
find_package(Doxygen REQUIRED OPTIONAL_COMPONENTS dot)

# Doxygen::dot exists only when Graphviz was found. (DOXYGEN_DOT_FOUND
# isn't set reliably across CMake versions.)
if(TARGET Doxygen::dot AND NOT DOC_DISABLE_DOT)
    set(HAVE_DOT "YES")
    get_filename_component(DOC_DOT_PATH "${DOXYGEN_DOT_EXECUTABLE}" DIRECTORY)
else()
    set(HAVE_DOT "NO")
    set(DOC_DOT_PATH "")
    if(NOT DOC_DISABLE_DOT)
        message(STATUS "Graphviz (dot) not found: documentation will have no graphs")
    endif()
endif()

if(DOC_GEN_PDF)
    find_program(PDFLATEX_EXECUTABLE pdflatex)
    find_program(MAKE_EXECUTABLE NAMES make gmake)
    if(NOT PDFLATEX_EXECUTABLE OR NOT MAKE_EXECUTABLE)
        message(FATAL_ERROR "DOC_GEN_PDF needs pdflatex and make. Install TeX Live with its extra LaTeX packages (Debian/Ubuntu: texlive-latex-extra texlive-plain-generic), or set DOC_GEN_PDF=OFF.")
    endif()
endif()

# -------------------------------------------------------------------
# Values substituted into Doxyfile.in
# -------------------------------------------------------------------
macro(doc_yes_no out flag)
    if(${flag})
        set(${out} "YES")
    else()
        set(${out} "NO")
    endif()
endmacro()

doc_yes_no(DOC_GENERATE_HTML  DOC_GEN_HTML)
doc_yes_no(DOC_GENERATE_LATEX DOC_GEN_PDF)
doc_yes_no(DOC_GENERATE_RTF   DOC_GEN_RTF)
doc_yes_no(DOC_GENERATE_MAN   DOC_GEN_MAN)
doc_yes_no(DOC_EXTRACT_ALL_YN DOC_EXTRACT_ALL)

if(DOC_WARN_AS_ERROR)
    set(DOC_WARN_AS_ERROR_VALUE "FAIL_ON_WARNINGS")
else()
    set(DOC_WARN_AS_ERROR_VALUE "NO")
endif()

# Each input quoted, so paths with spaces survive.
set(DOC_INPUT_QUOTED "")
foreach(path IN LISTS DOC_INPUT)
    if(NOT IS_ABSOLUTE "${path}")
        set(path "${DOC_PROJECT_ROOT}/${path}")
    endif()
    string(APPEND DOC_INPUT_QUOTED " \"${path}\"")
endforeach()

set(DOXYFILE ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in ${DOXYFILE} @ONLY)

# -------------------------------------------------------------------
# "doc" target
# -------------------------------------------------------------------
set(DOC_COMMANDS COMMAND ${CMAKE_COMMAND} -E make_directory "${DOC_OUTPUT_DIR}"
                 COMMAND Doxygen::doxygen "${DOXYFILE}")

# Doxygen only writes LaTeX sources; build the PDF from them.
if(DOC_GEN_PDF)
    string(MAKE_C_IDENTIFIER "${DOC_PROJECT_NAME}" DOC_PDF_NAME)
    list(APPEND DOC_COMMANDS
        COMMAND ${MAKE_EXECUTABLE} -s -C "${DOC_OUTPUT_DIR}/latex"
        COMMAND ${CMAKE_COMMAND} -E copy "${DOC_OUTPUT_DIR}/latex/refman.pdf" "${DOC_OUTPUT_DIR}/${DOC_PDF_NAME}.pdf")
endif()

add_custom_target(doc ALL
    ${DOC_COMMANDS}
    WORKING_DIRECTORY "${DOC_PROJECT_ROOT}"
    COMMENT "Generating documentation with Doxygen ${DOXYGEN_VERSION}"
    SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in
    VERBATIM)