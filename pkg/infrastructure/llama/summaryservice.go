package llama

import (
	"strings"

	"github.com/nightnoryu/nightcall/pkg/app"

	"github.com/go-skynet/go-llama.cpp"
)

const (
	threads   = 4
	tokens    = 128
	gpulayers = 0
	seed      = -1
)

type summaryService struct {
	modelPath string
}

func NewSummaryService() app.SummaryService {
	return &summaryService{}
}

func (s *summaryService) GenerateSummary(input string) (string, error) {
	l, err := llama.New(s.modelPath, llama.EnableF16Memory, llama.SetContext(128), llama.EnableEmbeddings, llama.SetGPULayers(gpulayers))
	if err != nil {
		return "", err
	}

	query := "Summarise the following conversation:\n\n" + input
	var result strings.Builder

	_, err = l.Predict(query, llama.Debug, llama.SetTokenCallback(func(token string) bool {
		result.WriteString(token)
		return true
	}), llama.SetTokens(tokens), llama.SetThreads(threads), llama.SetTopK(90), llama.SetTopP(0.86), llama.SetStopWords("llama"), llama.SetSeed(seed))
	if err != nil {
		return "", err
	}

	return result.String(), nil
}
