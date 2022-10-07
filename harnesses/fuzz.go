package myfuzz
import (
	"github.com/cosmos/iavl/fastnode"
)

func Fuzz(data []byte) int {
	fastnode.DeserializeNode(data, data)
	return 1
}
