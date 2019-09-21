all: check reverse talk

check:
	dmd check.d

reverse:
	dmd reverse.d

talk:
	dmd talk.d

run: all
	./talk
