package app

type SummaryService interface {
	GenerateSummary(input string) (string, error)
}
