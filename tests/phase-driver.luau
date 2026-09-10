-- Presentation phases are real server phases, not skipped by mutating state in tests.
function Mock.finishShow(e,includeIntro)
	while e.state=="BREACH_REACT"or e.state=="OFFER_ROLL"or(includeIntro and e.state=="SHOWTIME")do
		Mock.advance(math.max(0,e.deadline-Mock.time)+.001)
	end
end
