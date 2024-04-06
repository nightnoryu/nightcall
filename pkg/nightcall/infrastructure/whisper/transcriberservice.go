package whisper

import (
	"io"
	"os"
	"strings"

	"nightcall/pkg/nightcall/app"

	"github.com/ggerganov/whisper.cpp/bindings/go/pkg/whisper"
	"github.com/go-audio/wav"
)

type transcriberService struct {
	modelPath string
}

func NewTranscriberService(modelPath string) app.TranscriberService {
	return &transcriberService{
		modelPath: modelPath,
	}
}

func (s *transcriberService) Transcribe(audioFilePath string) (string, error) {
	model, err := whisper.New(s.modelPath)
	if err != nil {
		return "", err
	}
	defer model.Close()

	context, err := model.NewContext()
	if err != nil {
		return "", err
	}

	samples, err := s.loadSamples(audioFilePath)
	if err != nil {
		return "", err
	}

	context.ResetTimings()
	err = context.Process(samples, nil, nil)
	if err != nil {
		return "", err
	}

	var result strings.Builder
	for {
		segment, err := context.NextSegment()
		if err == io.EOF {
			break
		} else if err != nil {
			return "", err
		}

		result.WriteString(segment.Text)
	}

	return result.String(), nil
}

func (s *transcriberService) loadSamples(inputFilename string) ([]float32, error) {
	file, err := os.Open(inputFilename)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	decoder := wav.NewDecoder(file)
	buf, err := decoder.FullPCMBuffer()
	if err != nil {
		return nil, err
	}

	return buf.AsFloat32Buffer().Data, nil
}
