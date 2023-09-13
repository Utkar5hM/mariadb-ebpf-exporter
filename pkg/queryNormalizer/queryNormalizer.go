package queryNormalizer

import (
	"regexp"
	"strings"
)

type AbstractQuery struct{}

func Normalize(query string) string {
	query = strings.ToLower(strings.TrimSpace(query))
	query = removeComments(query)
	query = removeQuotes(query)
	query = removeConstants(query)
	query = removeDoubleSpaces(query)
	query = removeNewlines(query)
	query = removeInValues(query)
	query = removeOffsets(query)
	return strings.TrimSpace(query)
}

func removeComments(query string) string {
	commentRe := regexp.MustCompile(`(?s)(?:--|#)[^'"\r\n]*|/\*[^!].*?\*/`)
	return commentRe.ReplaceAllString(query, " ")
}

func removeNewlines(query string) string {
	return strings.ReplaceAll(query, "\n", " ")
}

func removeDoubleSpaces(query string) string {
	spaceRe := regexp.MustCompile(`\s+`)
	return spaceRe.ReplaceAllString(query, " ")
}

func removeQuotes(query string) string {
	return strings.ReplaceAll(query, `"`, "")
}

func removeConstants(query string) string {
	regex := regexp.MustCompile(`".*?"|'.*?'|\b(false|true|null)\b|\b[0-9+-]+\b`)
	return regex.ReplaceAllString(query, "?")
}

func removeInValues(query string) string {
	inValuesRe := regexp.MustCompile(`\b(in|values?)(?:[\s,]*\([\s?,]*\))+`)
	return inValuesRe.ReplaceAllString(query, "$1(?+)")
}

func removeOffsets(query string) string {
	offsetRe := regexp.MustCompile(`\blimit \?(?:, ?\?| offset \?)?`)
	return offsetRe.ReplaceAllString(query, "limit ?")
}
