package app

type TranscriberService interface {
	Transcribe(audioFilePath string) (string, error)
}
