// modules/config/schema_helper.nf

import groovy.json.JsonSlurper

def showSchemaHelp(String schemaPath) {
    def schemaFile = new File(schemaPath)
    def jsonSlurper = new JsonSlurper()
    def schema = jsonSlurper.parse(schemaFile)

    // ANSI escape codes for styling
    def ANSI_BOLD = "\u001B[1m"
    def ANSI_UNDERLINE = "\u001B[4m"
    def ANSI_RESET = "\u001B[0m"
    def ANSI_GREY = "\u001B[90m"

    // Title and Description
    def title = schema['title'] ?: ''
    def description = schema['description'] ?: ''

    def output = "\n"

    // Add Title and Description
    if (title) {
        output += "${ANSI_BOLD}${ANSI_UNDERLINE}${title}${ANSI_RESET}\n"
    }
    if (description) {
        output += "${description}\n\n"
    }

    def properties = schema['items']['properties']
    def requiredFields = schema['items']['required'] ?: []

    def allColumns = []

    properties.each { key, value ->
        def column = [:]
        column.key = key
        column.type = extractType(value)
        column.description = value['description'] ?: ''
        column.defaultValue = value['default'] ?: ''
        column.required = requiredFields.contains(key)
        allColumns << column
    }

    def maxKeyLength = allColumns.collect { it.key.size() }.max() ?: 10
    def maxTypeLength = allColumns.collect { it.type.size() }.max() ?: 10

    // Underlined Headers
    output += "${ANSI_UNDERLINE}Required columns:${ANSI_RESET}\n"

    allColumns.findAll { it.required }.each { col ->
        def typeStr = "${ANSI_GREY}[${col.type}]${ANSI_RESET}"
        def desc = col.description
        if (col.defaultValue) {
            desc += " ${ANSI_GREY}[default: ${col.defaultValue}]${ANSI_RESET}"
        }
        output += String.format("  %-${maxKeyLength}s  %s  %s\n", col.key, typeStr, desc)
    }

    output += "\n${ANSI_UNDERLINE}Optional columns:${ANSI_RESET}\n"

    allColumns.findAll { !it.required }.each { col ->
        def typeStr = "${ANSI_GREY}[${col.type}]${ANSI_RESET}"
        def desc = col.description
        if (col.defaultValue) {
            desc += " ${ANSI_GREY}[default: ${col.defaultValue}]${ANSI_RESET}"
        }
        output += String.format("  %-${maxKeyLength}s  %s  %s\n", col.key, typeStr, desc)
    }

    output += "-${ANSI_GREY}----------------------------------------------------${ANSI_RESET}-"
}

def extractType(value) {
    def types = []

    if (value['type']) {
        types << value['type']
    } else if (value['format']) {
        types << value['format']
    }

    if (value['anyOf']) {
        value['anyOf'].each { subValue ->
            if (subValue['type']) {
                types << subValue['type']
            } else if (subValue['format']) {
                types << subValue['format']
            }
        }
    }

    types = types.unique()
    def typeStr = types.join('/')

    return typeStr ?: 'unknown'
}