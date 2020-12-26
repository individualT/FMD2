function Init()
	local cat = 'Raw'
	local function AddWebsiteModule(id, name, url)
		local m = NewWebsiteModule()
		m.ID                         = id
		m.Category                   = cat
		m.Name                       = name
		m.RootURL                    = url
		m.TotalDirectory             = 1
		m.OnGetInfo                  = 'GetInfo'
		m.OnGetPageNumber            = 'GetPageNumber'
		m.OnGetNameAndLink           = 'GetNameAndLink'
		m.OnBeforeDownloadImage      = 'BeforeDownloadImage'
	end
	AddWebsiteModule('9e96846a035646988e1b2eb0f356d795', 'LoveHeaven', 'https://loveheaven.net')
	AddWebsiteModule('4c089029492f43c98d9f27a23403247b', 'HanaScan', 'https://hanascan.com')
	AddWebsiteModule('010777f53bf2414fad039b9567c8a9ce', 'KissAway', 'https://kissaway.net')
	AddWebsiteModule('794187d0e92e4933bf63812438d69017', 'Manhwa18', 'https://manhwa18.com')
	AddWebsiteModule('9054606f128e4914ae646032215915e5', 'LoveHug', 'https://lovehug.net')

	cat = 'English'
	AddWebsiteModule('80427d9a7b354f04a8f432b345f0f640', 'MangaWeek', 'https://mangaweek.com')
	AddWebsiteModule('570e716a029e45cabccc2b660ed81425', 'ManhwaScan', 'https://manhwascan.com')
	AddWebsiteModule('694ff34a6ae4469fbdaecf8d3aebb6eb', 'ManhuaScan', 'https://manhuascan.com')
	AddWebsiteModule('3b7ab0c7342f4783910f7842ea05630b', 'EcchiScan', 'https://ecchiscan.com')
	AddWebsiteModule('f488bcb1911b4f21baa1ab65ef9ca61c', 'HeroScan', 'https://heroscan.com')
	
	cat = 'English-Scanlation'
	AddWebsiteModule('7fb5fbed6d3a44fe923ecc7bf929e6cb', 'LHTranslation', 'https://lhtranslation.net')
end

function GetInfo()
	MANGAINFO.URL = MaybeFillHost(MODULE.RootURL, URL)
	if HTTP.GET(MANGAINFO.URL) then
		local x = CreateTXQuery(HTTP.Document)
		MANGAINFO.Title     = Trim(SeparateLeft(x.XPathString('//div[@class="container"]//li[3]//span'), '- Raw'))
		if MANGAINFO.Title == '' then MANGAINFO.Title = Trim(x.XPathString('//div[contains(@class, "container")]//li[3]//span'):gsub('- RAW', ''):gsub('%(MANGA%)', '')) end
		MANGAINFO.CoverLink = MaybeFillHost(MODULE.RootURL, x.XPathString('//img[@class="thumbnail"]/@src'))
		MANGAINFO.Status    = MangaInfoStatusIfPos(x.XPathString('//ul[@class="manga-info"]/li[contains(., "Status")]//a'))
		MANGAINFO.Authors   = x.XPathString('//ul[@class="manga-info"]/li[contains(., "Author")]//a')
		MANGAINFO.Genres    = x.XPathStringAll('//ul[@class="manga-info"]/li[contains(., "Genre")]//a')
		MANGAINFO.Summary   = x.XPathString('string-join(//div[./h3="Description"]//p, "\r\n")')
		if MANGAINFO.Summary == '' then MANGAINFO.Summary = x.XPathString('//div[@class="detail"]/div[@class="content"]') end
		x.XPathHREFAll('//div[@id="tab-chapper"]//table/tbody/tr/td/a', MANGAINFO.ChapterLinks, MANGAINFO.ChapterNames)
		if MANGAINFO.ChapterLinks.Count == 0 then
			x.XPathHREFAll('//div[@id="list-chapters"]//a[@class="chapter"]', MANGAINFO.ChapterLinks, MANGAINFO.ChapterNames)
		end
		if MANGAINFO.ChapterLinks.Count == 0 then
			x.XPathHREFTitleAll('//ul[contains(@class, "list-chapters")]/a', MANGAINFO.ChapterLinks, MANGAINFO.ChapterNames)
		end
		for i = 0, MANGAINFO.ChapterLinks.Count-1 do
			MANGAINFO.ChapterLinks[i] = MODULE.RootURL .. '/' .. MANGAINFO.ChapterLinks[i]
		end
		MANGAINFO.ChapterLinks.Reverse(); MANGAINFO.ChapterNames.Reverse()
		HTTP.Reset()
		HTTP.Headers.Values['Referer'] = MANGAINFO.URL
		return no_error
	else
		return net_problem
	end
end

function GetPageNumber()
	TASK.PageLinks.Clear()
	local u = MaybeFillHost(MODULE.RootURL, URL)
	if HTTP.GET(u) then
		local x = CreateTXQuery(HTTP.Document)
		if MODULE.ID == '794187d0e92e4933bf63812438d69017' then -- manhwa18
			local v = x.XPath('//img[contains(@class, "chapter-img")]/@src')
			for i = 1, v.Count do
				local s = v.Get(i).ToString()
				s = s:gsub('app/', 'https://manhwa18.com/app/'):gsub('https://manhwa18.net/https://manhwa18.com', 'https://manhwa18.net')
				if string.find(s, ".iff") == nil then
					TASK.PageLinks.Add(s)
				end
			end
		elseif MODULE.ID == '9e96846a035646988e1b2eb0f356d795' then -- loveheaven
			x.XPathStringAll('//img[contains(@class, "chapter-img")]/@data-src', TASK.PageLinks)
		elseif MODULE.ID == 'f488bcb1911b4f21baa1ab65ef9ca61c' or MODULE.ID == '010777f53bf2414fad039b9567c8a9ce' then -- HeroScan, KissAway
			x.XPathStringAll('//img[contains(@class, "chapter-img")]/@data-original', TASK.PageLinks)
		elseif MODULE.ID == '9054606f128e4914ae646032215915e5' then -- LoveHug
			local v for v in x.XPath('//img[contains(@class, "chapter-img")]').Get() do
				local src = v.GetAttribute('src')
				if src:find('pagespeed') then
					src = v.GetAttribute('data-pagespeed-lazy-src')
				end
			TASK.PageLinks.Add(src)
			end
		else
			x.XPathStringAll('//img[contains(@class, "chapter-img")]/@src', TASK.PageLinks)
		end
	else
		return false
	end
	return true
end

function GetNameAndLink()
	if HTTP.GET(MODULE.RootURL .. '/manga-list.html?listType=allABC') then
		local x = CreateTXQuery(HTTP.Document)
		if MODULE.ID == '694ff34a6ae4469fbdaecf8d3aebb6eb' then -- manhuascan
			x.XPathHREFAll('//div[@id="Character"]//a', LINKS, NAMES)
		else
			local v; for v in x.XPath('//span[@manga-slug]//a').Get() do
				NAMES.Add(Trim(SeparateLeft(v.ToString(), '- Raw')))
				LINKS.Add(v.GetAttribute('href'))
			end
		end
		return no_error
	else
		return net_problem
	end
end

function BeforeDownloadImage()
	HTTP.Headers.Values['Referer'] = ' ' .. MaybeFillHost(MODULE.RootURL, TASK.ChapterLinks[TASK.CurrentDownloadChapterPtr])
	return true
end
