redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)

function dl_cb(arg, data)
end
function get_admin ()
	if redis:get('bot1adminset') then
		return true
	else
   		print("\n\27[32m  لازمه کارکرد صحیح ، فرامین و امورات مدیریتی ربات  <<\n                    تعریف کاربری به عنوان مدیر است\n\27[34m                   آیدی خود را به عنوان مدیر وارد کنید\n\27[32m    شما می توانید شناسه خود را از بات زیر به دست آورید\n\27[34m        ربات:       @userinfobot")
    	print("\n\27[32m >> Tabchi Bot need a fullaccess user (ADMIN)\n\27[34m Imput Your ID as the ADMIN\n\27[32m You can get your ID of this bot\n\27[34m                 @userinfobot")
    	print("\n\27[36m                      : شناسه عددی ادمین را وارد کنید << \n >> Imput the Admin ID :\n\27[31m                 ")
    	local admin=io.read()
		redis:del("bot1admin")
    	redis:sadd("bot1admin", admin)
		redis:set('bot1adminset',true)
    	return print("\n\27[36m     ADMIN ID |\27[32m ".. admin .." \27[36m| شناسه ادمین")
	end
end
function get_bot (i, naji)
	function bot_info (i, naji)
		redis:set("bot1id",naji.id_)
		if naji.first_name_ then
			redis:set("bot1fname",naji.first_name_)
		end
		if naji.last_name_ then
			redis:set("bot1lanme",naji.last_name_)
		end
		redis:set("bot1num",naji.phone_number_)
		return naji.id_
	end
	tdcli_function ({ID = "GetMe",}, bot_info, nil)
end
function reload(chat_id,msg_id)
	loadfile("./bot-1.lua")()
	send(chat_id, msg_id, "<i>با موفقیت انجام شد.</i>")
end
function is_naji(msg)
    local var = false
	local hash = 'bot1admin'
	local user = msg.sender_user_id_
    local Naji = redis:sismember(hash, user)
	if Naji then
		var = true
	end
	return var
end
function writefile(filename, input)
	local file = io.open(filename, "w")
	file:write(input)
	file:flush()
	file:close()
	return true
end
function process_join(i, naji)
	if naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 85
		redis:setex("bot1maxjoin", tonumber(Time), true)
	else
		redis:srem("bot1goodlinks", i.link)
		redis:sadd("bot1savedlinks", i.link)
	end
end
function process_link(i, naji)
	if (naji.is_group_ or naji.is_supergroup_channel_) then
		if redis:get('bot1maxgpmmbr') then
			if naji.member_count_ >= tonumber(redis:get('bot1maxgpmmbr')) then
				redis:srem("bot1waitelinks", i.link)
				redis:sadd("bot1goodlinks", i.link)
			else
				redis:srem("bot1waitelinks", i.link)
				redis:sadd("bot1savedlinks", i.link)
			end
		else
			redis:srem("bot1waitelinks", i.link)
			redis:sadd("bot1goodlinks", i.link)
		end
	elseif naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 85
		redis:setex("bot1maxlink", tonumber(Time), true)
	else
		redis:srem("bot1waitelinks", i.link)
	end
end
function find_link(text)
	if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
		local text = text:gsub("t.me", "telegram.me")
		local text = text:gsub("telegram.dog", "telegram.me")
		for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
			if not redis:sismember("bot1alllinks", link) then
				redis:sadd("bot1waitelinks", link)
				redis:sadd("bot1alllinks", link)
			end
		end
	end
end
function add(id)
	local Id = tostring(id)
	if not redis:sismember("bot1all", id) then
		if Id:match("^(%d+)$") then
			redis:sadd("bot1users", id)
			redis:sadd("bot1all", id)
		elseif Id:match("^-100") then
			redis:sadd("bot1supergroups", id)
			redis:sadd("bot1all", id)
		else
			redis:sadd("bot1groups", id)
			redis:sadd("bot1all", id)
		end
	end
	return true
end
function rem(id)
	local Id = tostring(id)
	if redis:sismember("bot1all", id) then
		if Id:match("^(%d+)$") then
			redis:srem("bot1users", id)
			redis:srem("bot1all", id)
		elseif Id:match("^-100") then
			redis:srem("bot1supergroups", id)
			redis:srem("bot1all", id)
		else
			redis:srem("bot1groups", id)
			redis:srem("bot1all", id)
		end
	end
	return true
end
function send(chat_id, msg_id, text)
	 tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessageTypingAction",
      progress_ = 100
    }
  }, cb or dl_cb, cmd)
	tdcli_function ({
		ID = "SendMessage",
		chat_id_ = chat_id,
		reply_to_message_id_ = msg_id,
		disable_notification_ = 1,
		from_background_ = 1,
		reply_markup_ = nil,
		input_message_content_ = {
			ID = "InputMessageText",
			text_ = text,
			disable_web_page_preview_ = 1,
			clear_draft_ = 0,
			entities_ = {},
			parse_mode_ = {ID = "TextParseModeHTML"},
		},
	}, dl_cb, nil)
end
get_admin()
redis:set("bot1start", true)
function tdcli_update_callback(data)
	if data.ID == "UpdateNewMessage" then
		if redis:get("bot1start") then
			redis:del("bot1start")
			tdcli_function ({
				ID = "GetChats",
				offset_order_ = 9223372036854775807,
				offset_chat_id_ = 0,
				limit_ = 10000},
			function (i,naji)
				local list = redis:smembers("bot1users")
				for i, v in ipairs(list) do
					tdcli_function ({
						ID = "OpenChat",
						chat_id_ = v
					}, dl_cb, cmd)
				end
			end, nil)
		end
		if not redis:get("bot1maxlink") then
			if redis:scard("bot1waitelinks") ~= 0 then
				local links = redis:smembers("bot1waitelinks")
				for x,y in ipairs(links) do
					if x == 6 then redis:setex("bot1maxlink", 65, true) return end
					tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
				end
			end
		end
		if redis:get("bot1maxgroups") and redis:scard("bot1supergroups") >= tonumber(redis:get("bot1maxgroups")) then 
			redis:set("bot1maxjoin", true)
			redis:set("bot1offjoin", true)
		end
		if not redis:get("bot1maxjoin") then
			if redis:scard("bot1goodlinks") ~= 0 then
				local links = redis:smembers("bot1goodlinks")
				for x,y in ipairs(links) do
					tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
					if x == 2 then redis:setex("bot1maxjoin", 65, true) return end
				end
			end
		end
		local msg = data.message_
		local bot_id = redis:get("bot1id") or get_bot()
		if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 178220800) then
			local c = (msg.content_.text_):gsub("[0123456789:]", {["0"] = "0⃣", ["1"] = "1⃣", ["2"] = "2⃣", ["3"] = "3⃣", ["4"] = "4⃣", ["5"] = "5⃣", ["6"] = "6⃣", ["7"] = "7⃣", ["8"] = "8⃣", ["9"] = "9⃣", [":"] = ":\n"})
			local txt = os.date("<i>پیام ارسال از شده از تلگرام به تاریخ🗓</i><code> %Y-%m-%d </code><i>🗓 و ساعت⏰</i><code> %X </code><i>⏰ (به وقت سرور)</i>")
			for k,v in ipairs(redis:smembers('bot1admin')) do
				send(v, 0, txt.."\n\n"..c)
			end
		end
		if tostring(msg.chat_id_):match("^(%d+)") then
			if not redis:sismember("bot1all", msg.chat_id_) then
				redis:sadd("bot1users", msg.chat_id_)
				redis:sadd("bot1all", msg.chat_id_)
			end
		end
		add(msg.chat_id_)
		if msg.date_ < os.time() - 150 then
			return false
		end
		if msg.content_.ID == "MessageText" then
			local text = msg.content_.text_
			local matches
			if redis:get("bot1link") then
				find_link(text)
			end
			if is_naji(msg) then
				find_link(text)
				if text:match("^(حذف لینک) (.*)$") then
					local matches = text:match("^حذف لینک (.*)$")
					if matches == "عضویت" then
						redis:del("bot1goodlinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار عضویت پاکسازی شد .")
					elseif matches == "تایید" then
						redis:del("bot1waitelinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار تایید پاکسازی شد.")
					elseif matches == "ذخیره شده" then
						redis:del("bot1savedlinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های ذخیره شده پاکسازی شد.")
					end
				elseif text:match("^(حذف کلی لینک) (.*)$") then
					local matches = text:match("^حذف کلی لینک (.*)$")
					if matches == "عضویت" then
						local list = redis:smembers("bot1goodlinks")
						for i, v in ipairs(list) do
							redis:srem("bot1alllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار عضویت پاکسازی شد.")
						redis:del("bot1goodlinks")
					elseif matches == "تایید" then
						local list = redis:smembers("bot1waitelinks")
						for i, v in ipairs(list) do
							redis:srem("bot1alllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار عضویت پاکسازی شد.")
						redis:del("bot1waitelinks")
					elseif matches == "ذخیره شده" then
						local list = redis:smembers("bot1savedlinks")
						for i, v in ipairs(list) do
							redis:srem("bot1alllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های ذخیره شده به طور کامل پاکسازی شد.")
						redis:del("bot1savedlinks")
					end
				elseif text:match("^(توقف) (.*)$") then
					local matches = text:match("^توقف (.*)$")
					if matches == "عضویت" then	
						redis:set("bot1maxjoin", true)
						redis:set("bot1offjoin", true)
						return send(msg.chat_id_, msg.id_, " عضویت خودکار متوقف شد.")
					elseif matches == "تایید لینک" then	
						redis:set("bot1maxlink", true)
						redis:set("bot1offlink", true)
						return send(msg.chat_id_, msg.id_, " تایید لینک های در انتظار متوقف شد.")
					elseif matches == "شناسایی لینک" then	
						redis:del("bot1link")
						return send(msg.chat_id_, msg.id_, " شناسایی لینک متوقف شد.")
					elseif matches == "افزودن مخاطب" then	
						redis:del("bot1savecontacts")
						return send(msg.chat_id_, msg.id_, " افزودن خودکار مخاطبین متوقف شد.")
					end
				elseif text:match("^(شروع) (.*)$") then
					local matches = text:match("^شروع (.*)$")
					if matches == "عضویت" then	
						redis:del("bot1maxjoin")
						redis:del("bot1offjoin")
						return send(msg.chat_id_, msg.id_, " عضویت خودکار فعال شد.")
					elseif matches == "تایید لینک" then	
						redis:del("bot1maxlink")
						redis:del("bot1offlink")
						return send(msg.chat_id_, msg.id_, " تایید لینک های در انتظار تایید فعال شد.")
					elseif matches == "شناسایی لینک" then	
						redis:set("bot1link", true)
						return send(msg.chat_id_, msg.id_, " شناسایی لینک فعال شد.")
					elseif matches == "افزودن مخاطبین" then	
						redis:set("bot1savecontacts", true)
						return send(msg.chat_id_, msg.id_, " افزودن مخاطبین فعال شد.")
					end
				elseif text:match("^(حداکثر گروه) (%d+)$") then
					local matches = text:match("%d+")
					redis:set('bot1maxgroups', tonumber(matches))
					return send(msg.chat_id_, msg.id_, "<i> حداکثر گروه : </i><b> "..matches.." </b>")
				elseif text:match("^(حداقل اعضا) (%d+)$") then
					local matches = text:match("%d+")
					redis:set('bot1maxgpmmbr', tonumber(matches))
					return send(msg.chat_id_, msg.id_, "<i>عضویت در گرو های حداقل </i><b> "..matches.." </b> عضو تنظیم شد.")
				elseif text:match("^(حذف حداکثر گروه)$") then
					redis:del('bot1maxgroups')
					return send(msg.chat_id_, msg.id_, "تعیین حد مجاز گروه نادیده گرفته شد.")
				elseif text:match("^(حذف حداقل اعضا)$") then
					redis:del('bot1maxgpmmbr')
					return send(msg.chat_id_, msg.id_, "تعیین حد مجاز اعضای گروه نادیده گرفته شد.")
				elseif text:match("^(افزودن مدیر) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('bot1admin', matches) then
						return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر الآن مدیر شد.</i>")
					elseif redis:sismember('bot1mod', msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "شما دسترسی ندارید.")
					else
						redis:sadd('bot1admin', matches)
						redis:sadd('bot1mod', matches)
						return send(msg.chat_id_, msg.id_, "<i>کاربر مدیر شده</i>")
					end
				elseif text:match("^(افزودن مدیرکل) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('bot1mod',msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "شما نمی توانید .")
					end
					if redis:sismember('bot1mod', matches) then
						redis:srem("bot1mod",matches)
						redis:sadd('bot1admin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "کاربر مورد نظر مقام مدیر کل شد .")
					elseif redis:sismember('bot1admin',matches) then
						return send(msg.chat_id_, msg.id_, 'در حال حاضر مدیر است.')
					else
						redis:sadd('bot1admin', matches)
						redis:sadd('bot1admin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "کاربر به مقام کل منصوب شد.")
					end
				elseif text:match("^(حذف مدیر) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('bot1mod', msg.sender_user_id_) then
						if tonumber(matches) == msg.sender_user_id_ then
								redis:srem('bot1admin', msg.sender_user_id_)
								redis:srem('bot1mod', msg.sender_user_id_)
							return send(msg.chat_id_, msg.id_, "شما دیگر مدیر نیستید.")
						end
						return send(msg.chat_id_, msg.id_, "شما دسترسی ندارید.")
					end
					if redis:sismember('bot1admin', matches) then
						if  redis:sismember('bot1admin'..msg.sender_user_id_ ,matches) then
							return send(msg.chat_id_, msg.id_, "شما نمی توانید مدیری که مقام دارد را حذف کنید.")
						end
						redis:srem('bot1admin', matches)
						redis:srem('bot1mod', matches)
						return send(msg.chat_id_, msg.id_, "کاربر از مقام مدیریت حذف شد.")
					end
					return send(msg.chat_id_, msg.id_, "کاربر مورد نظر مدیر نمی باشد.")
				elseif text:match("^(تازه سازی ربات)$") then
					get_bot()
					return send(msg.chat_id_, msg.id_, "<i>مشخصات فردی بروز شد.</i>")
				elseif text:match("ریپورت") then
					tdcli_function ({
						ID = "SendBotStartMessage",
						bot_user_id_ = 178220800,
						chat_id_ = 178220800,
						parameter_ = 'start'
					}, dl_cb, nil)
				elseif text:match("^(/reload)$") then
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^(لیست) (.*)$") then
					local matches = text:match("^لیست (.*)$")
					local naji
					if matches == "مخاطبین" then
						return tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},
						function (I, Naji)
							local count = Naji.total_count_
							local text = "مخاطبین : \n"
							for i =0 , tonumber(count) - 1 do
								local user = Naji.users_[i]
								local firstname = user.first_name_ or ""
								local lastname = user.last_name_ or ""
								local fullname = firstname .. " " .. lastname
								text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id_) .. "] = " .. tostring(user.phone_number_) .. "  \n"
							end
							writefile("bot1_contacts.txt", text)
							tdcli_function ({
								ID = "SendMessage",
								chat_id_ = I.chat_id,
								reply_to_message_id_ = 0,
								disable_notification_ = 0,
								from_background_ = 1,
								reply_markup_ = nil,
								input_message_content_ = {ID = "InputMessageDocument",
								document_ = {ID = "InputFileLocal",
								path_ = "bot1_contacts.txt"},
								caption_ = "مخاطبین شماره 1"}
							}, dl_cb, nil)
							return io.popen("rm -rf bot1_contacts.txt"):read("*all")
						end, {chat_id = msg.chat_id_})
					elseif matches == "پاسخ های خودکار" then
						local text = "<i>لیست پاسخ های خودکار :</i>\n\n"
						local answers = redis:smembers("bot1answerslist")
						for k,v in pairs(answers) do
							text = tostring(text) .. "<i>l" .. tostring(k) .. "l</i>  " .. tostring(v) .. " : " .. tostring(redis:hget("bot1answers", v)) .. "\n"
						end
						if redis:scard('bot1answerslist') == 0  then text = "<code>       EMPTY</code>" end
						return send(msg.chat_id_, msg.id_, text)
					elseif matches == "مسدود" then
						naji = "bot1blockedusers"
					elseif matches == "شخصی" then
						naji = "bot1users"
					elseif matches == "گروه" then
						naji = "bot1groups"
					elseif matches == "سوپرگروه" then
						naji = "bot1supergroups"
					elseif matches == "لینک" then
						naji = "bot1savedlinks"
					elseif matches == "مدیر" then
						naji = "bot1admin"
					else
						return true
					end
					local list =  redis:smembers(naji)
					local text = tostring(matches).." : \n"
					for i, v in pairs(list) do
						text = tostring(text) .. tostring(i) .. "-  " .. tostring(v).."\n"
					end
					writefile(tostring(naji)..".txt", text)
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = 0,
						disable_notification_ = 0,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {ID = "InputMessageDocument",
							document_ = {ID = "InputFileLocal",
							path_ = tostring(naji)..".txt"},
						caption_ = "لیست "..tostring(matches).." شماره 1"}
					}, dl_cb, nil)
					return io.popen("rm -rf "..tostring(naji)..".txt"):read("*all")
				elseif text:match("^(وضعیت مشاهده) (.*)$") then
					local matches = text:match("^وضعیت مشاهده (.*)$")
					if matches == "ان" then
						redis:set("bot1markread", true)
						return send(msg.chat_id_, msg.id_, "<i>وضعیت پیام  >>  خوانده شده ✔️✔️\n</i><code>(تیک دوم)</code>")
					elseif matches == "اف" then
						redis:del("bot1markread")
						return send(msg.chat_id_, msg.id_, "<i>وضعیت پیام  >>  خوانده نشده ✔️\n</i><code>(تیک اول)</code>")
					end 
				elseif text:match("^(افزودن با پیام) (.*)$") then
					local matches = text:match("^افزودن با پیام (.*)$")
					if matches == "ان" then
						redis:set("bot1addmsg", true)
						return send(msg.chat_id_, msg.id_, "<i>پیام اضافه شدن مخاطبین فعال شد</i>")
					elseif matches == "اف" then
						redis:del("bot1addmsg")
						return send(msg.chat_id_, msg.id_, "<i>پیام ادد شدن مخاطب غیرفعال شد</i>")
					end
				elseif text:match("^(افزودن با شماره) (.*)$") then
					local matches = text:match("^افزودن با شماره (.*)$")
					if matches == "ان" then
						redis:set("bot1addcontact", true)
						return send(msg.chat_id_, msg.id_, "<i>ارسال شماره برای ادد کردن فعال شد</i>")
					elseif matches == "اف" then
						redis:del("bot1addcontact")
						return send(msg.chat_id_, msg.id_, "<i>ارسال شماره برای ادد کردن غیر فعال شد</i>")
					end
				elseif text:match("^(تنظیم پیام افزودن مخاطب) (.*)") then
					local matches = text:match("^تنظیم پیام افزودن مخاطب (.*)")
					redis:set("bot1addmsgtext", matches)
					return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخاطب تنظیم شد </i>:\n🔹 "..matches.." 🔹")
				elseif text:match('^(تنظیم جواب) "(.*)" (.*)') then
					local txt, answer = text:match('^تنظیم جواب "(.*)" (.*)')
					redis:hset("bot1answers", txt, answer)
					redis:sadd("bot1answerslist", txt)
					return send(msg.chat_id_, msg.id_, "<i>جواب برای | </i>" .. tostring(txt) .. "<i> | تنظیم شد به :</i>\n" .. tostring(answer))
				elseif text:match("^(حذف جواب) (.*)") then
					local matches = text:match("^حذف جواب (.*)")
					redis:hdel("bot1answers", matches)
					redis:srem("bot1answerslist", matches)
					return send(msg.chat_id_, msg.id_, "<i>جواب برای | </i>" .. tostring(matches) .. "<i> | از لیست خودکار پاک شد.</i>")
				elseif text:match("^(پاسخگوی خودکار) (.*)$") then
					local matches = text:match("^پاسخگوی خودکار (.*)$")
					if matches == "ان" then
						redis:set("bot1autoanswer", true)
						return send(msg.chat_id_, 0, "<i>پاسخگویی خودکار فعال شد</i>")
					elseif matches == "اف" then
						redis:del("bot1autoanswer")
						return send(msg.chat_id_, 0, "<i>حالت پاسخگویی خودکار غیر فعال شد</i>")
					end
				elseif text:match("^(بارگیری)$")then
					local list = {redis:smembers("bot1supergroups"),redis:smembers("bot1groups")}
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
						redis:set("bot1contacts", naji.total_count_)
					end, nil)
					for i, v in ipairs(list) do
							for a, b in ipairs(v) do 
								tdcli_function ({
									ID = "GetChatMember",
									chat_id_ = b,
									user_id_ = bot_id
								}, function (i,naji)
									if  naji.ID == "Error" then rem(i.id) 
									end
								end, {id=b})
							end
					end
					return send(msg.chat_id_,msg.id_,"<i>بارگیری آمار ربات شماره </i><code> 1 </code> با موفقیت انجام شد.")
				elseif text:match("^(وضعیت)$") then
					local s =  redis:get("bot1offjoin") and 0 or redis:get("bot1maxjoin") and redis:ttl("bot1maxjoin") or 0
					local ss = redis:get("bot1offlink") and 0 or redis:get("bot1maxlink") and redis:ttl("bot1maxlink") or 0
					local msgadd = redis:get("botBOT-IDaddmsg") and "✔️" or "✖️"
					local numadd = redis:get("botBOT-IDaddcontact") and "✔️" or "✖️"
					local txtadd = redis:get("botBOT-IDaddmsgtext") or  "خصوصی پیام بده"
					local autoanswer = redis:get("botBOT-IDautoanswer") and "✔️" or "✖️"
					local wlinks = redis:scard("botBOT-IDwaitelinks")
					local glinks = redis:scard("botBOT-IDgoodlinks")
					local links = redis:scard("botBOT-IDsavedlinks")
					local offjoin = redis:get("botBOT-IDoffjoin") and "✖️" or "✔️"
					local offlink = redis:get("botBOT-IDofflink") and "✖️" or "✔️"
					local gp = redis:get("botBOT-IDmaxgroups") or "تعیین نشده"
					local mmbrs = redis:get("botBOT-IDmaxgpmmbr") or "تعیین نشده"
					local nlink = redis:get("botBOT-IDlink") and "✔️" or "✖️"
					local contacts = redis:get("botBOT-IDsavecontacts") and "✔️" or "✖️"
					local fwd =  redis:get("botBOT-IDfwdtime") and "✔️" or "✖️" 
					local txt = "⚙️  <i>وضعیت اجرایی ربات</i><code> 1</code>\n\n"..tostring(offjoin).."<code> عضویت خودکار </code>\n"..tostring(offlink).."<code> تایید لینک خودکار </code>\n"..tostring(nlink).."<code> تشخیص لینک های عضویت </code>\n"..tostring(fwd).."<code> زمانبندی در ارسال </code>\n"..tostring(contacts).."<code> افزودن خودکار مخاطبین </code>\n" .. tostring(autoanswer) .."<code> حالت پاسخگویی خودکار </code>\n" .. tostring(numadd) .. "<code> افزودن مخاطب با شماره </code>\n" .. tostring(msgadd) .. "<code> افزودن مخاطب با پیام </code>\n\n〰〰〰ا〰〰〰\n📄<code> پیام افزودن مخاطب :</code>\n📍 " .. tostring(txtadd) .. " 📍\n〰〰〰ا〰〰〰\n\n⏫<code> سقف سوپر گروه ها  : </code><i>"..tostring(gp).."</i>\n⏬<code> کمترین تعداد اعضا گروه : </code><i>"..tostring(mmbrs).."</i>\n\n<code>▫️ لینک های ذخیره شده : </code><b>" .. tostring(links) .. "</b>\n<code>▪️	لینک های در انتظار عضویت : </code><b>" .. tostring(glinks) .. "</b>\n▫️   <b>" .. tostring(s) .. " </b><code>ثانیه تا عضویت مجدد</code>\n<code>▪️ لینک های در انتظار تایید : </code><b>" .. tostring(wlinks) .. "</b>\n▫   <b>" .. tostring(ss) .. " </b><code>ثانیه تا تایید لینک مجدد</code>\n\n⚠️ سازنده : @g0db0y"
					return send(msg.chat_id_, 0, txt)
				elseif text:match("^(امار)$") or text:match("^(آمار)$") or text:match("^(stats)$") or text:match("^(panel)$") then
					local gps = redis:scard("bot1groups")
					local sgps = redis:scard("bot1supergroups")
					local usrs = redis:scard("bot1users")
					local links = redis:scard("bot1savedlinks")
					local glinks = redis:scard("bot1goodlinks")
					local wlinks = redis:scard("bot1waitelinks")
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
					redis:set("bot1contacts", naji.total_count_)
					end, nil)
					local contacts = redis:get("bot1contacts")
					local text = [[
<i>📈 وضعیت و آمار ربات 📊</i>
          
<code>👤 گفت و گو های شخصی : </code>
<b>]] .. tostring(usrs) .. [[</b>
<code>👥 گروها : </code>
<b>]] .. tostring(gps) .. [[</b>
<code>🌐 سوپر گروه ها : </code>
<b>]] .. tostring(sgps) .. [[</b>
<code>📖 مخاطبین دخیره شده : </code>
<b>]] .. tostring(contacts)..[[</b>
<code>📂 لینک های ذخیره شده : </code>
<b>]] .. tostring(links)..[[</b>
]]
					return send(msg.chat_id_, 0, text)
				elseif (text:match("^(ارسال به) (.*)$") and msg.reply_to_message_id_ ~= 0) then
					local matches = text:match("^ارسال به (.*)$")
					local naji
					if matches:match("^(خصوصی)") then
						naji = "bot1users"
					elseif matches:match("^(گروه)$") then
						naji = "bot1groups"
					elseif matches:match("^(سوپرگروه)$") then
						naji = "bot1supergroups"
					else
						return true
					end
					local list = redis:smembers(naji)
					local id = msg.reply_to_message_id_
					if redis:get("bot1fwdtime") then
						for i, v in pairs(list) do
							tdcli_function({
								ID = "ForwardMessages",
								chat_id_ = v,
								from_chat_id_ = msg.chat_id_,
								message_ids_ = {[0] = id},
								disable_notification_ = 1,
								from_background_ = 1
							}, dl_cb, nil)
							if i % 4 == 0 then
								os.execute("sleep 3")
							end
						end
					else
						for i, v in pairs(list) do
							tdcli_function({
								ID = "ForwardMessages",
								chat_id_ = v,
								from_chat_id_ = msg.chat_id_,
								message_ids_ = {[0] = id},
								disable_notification_ = 1,
								from_background_ = 1
							}, dl_cb, nil)
						end
					end
						return send(msg.chat_id_, msg.id_, "<i>فرستاده شد</i>")
				elseif text:match("^(ارسال زمانی) (.*)$") then
					local matches = text:match("^ارسال زمانی (.*)$")
					if matches == "ان" then
						redis:set("bot1fwdtime", true)
						return send(msg.chat_id_,msg.id_,"<i>زمان بندی ارسال فعال شد.</i>")
					elseif matches == "اف" then
						redis:del("bot1fwdtime")
						return send(msg.chat_id_,msg.id_,"<i>زمان بندی ارسال غیر فعال شد.</i>")
					end
				elseif text:match("^(ارسال به سوپرگروه) (.*)") then
					local matches = text:match("^ارسال به سوپرگروه (.*)")
					local dir = redis:smembers("bot1supergroups")
					for i, v in pairs(dir) do
						tdcli_function ({
							ID = "SendMessage",
							chat_id_ = v,
							reply_to_message_id_ = 0,
							disable_notification_ = 0,
							from_background_ = 1,
							reply_markup_ = nil,
							input_message_content_ = {
								ID = "InputMessageText",
								text_ = matches,
								disable_web_page_preview_ = 1,
								clear_draft_ = 0,
								entities_ = {},
							parse_mode_ = nil
							},
						}, dl_cb, nil)
					end
                    return send(msg.chat_id_, msg.id_, "<i>با موفقیت فرستاده شد</i>")
				elseif text:match("^(مسدودیت) (%d+)$") then
					local matches = text:match("%d+")
					rem(tonumber(matches))
					redis:sadd("bot1blockedusers",matches)
					tdcli_function ({
						ID = "BlockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر مسدود شد</i>")
				elseif text:match("^(رفع مسدودیت) (%d+)$") then
					local matches = text:match("%d+")
					add(tonumber(matches))
					redis:srem("bot1blockedusers",matches)
					tdcli_function ({
						ID = "UnblockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>مسدودی کاربر حذف شد.</i>")	
				elseif text:match('^(تنظیم نام) "(.*)" (.*)') then
					local fname, lname = text:match('^تنظیم نام "(.*)" (.*)')
					tdcli_function ({
						ID = "ChangeName",
						first_name_ = fname,
						last_name_ = lname
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>نام جدید با موفقیت تنظیم شد.</i>")
				elseif text:match("^(تنظیم نام کاربری) (.*)") then
					local matches = text:match("^تنظیم نام کاربری (.*)")
						tdcli_function ({
						ID = "ChangeUsername",
						username_ = tostring(matches)
						}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>تلاش برای تنظیم نام کاربری...</i>')
				elseif text:match("^(حذف نام کاربری)$") then
					tdcli_function ({
						ID = "ChangeUsername",
						username_ = ""
					}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>نام کاربری با موفقیت پاک شد.</i>')
				elseif text:match('^(ارسال کن) "(.*)" (.*)') then
					local id, txt = text:match('^ارسال کن "(.*)" (.*)')
					send(id, 0, txt)
					return send(msg.chat_id_, msg.id_, "<i>ارسال شد</i>")
				elseif text:match("^(بگو) (.*)") then
					local matches = text:match("^بگو (.*)")
					return send(msg.chat_id_, 0, matches)
				elseif text:match("^(شناسه)$") then
					return send(msg.chat_id_, msg.id_, "<i>" .. msg.sender_user_id_ .."</i>")
				elseif text:match("^(خارج شو) (.*)$") then
					local matches = text:match("^خارج شو (.*)$") 	
					send(msg.chat_id_, msg.id_, 'ربات از گروه مورد نظر خارج شد')
					tdcli_function ({
						ID = "ChangeChatMemberStatus",
						chat_id_ = matches,
						user_id_ = bot_id,
						status_ = {ID = "ChatMemberStatusLeft"},
					}, dl_cb, nil)
					return rem(matches)
				elseif text:match("^(اد ال) (%d+)$") then
					local matches = text:match("%d+")
					local list = {redis:smembers("bot1groups"),redis:smembers("bot1supergroups")}
					for a, b in pairs(list) do
						for i, v in pairs(b) do 
							tdcli_function ({
								ID = "AddChatMember",
								chat_id_ = v,
								user_id_ = matches,
								forward_limit_ =  50
							}, dl_cb, nil)
						end	
					end
					return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر به تمامی گروه ها اضافه شد😉 </i>")
				elseif (text:match("^(ربات)$") and not msg.forward_info_)then
					return tdcli_function({
						ID = "ForwardMessages",
						chat_id_ = msg.chat_id_,
						from_chat_id_ = msg.chat_id_,
						message_ids_ = {[0] = msg.id_},
						disable_notification_ = 0,
						from_background_ = 1
					}, dl_cb, nil)
				elseif text:match("^(راهنما)$") then
					local txt = '🔞 راهنمای دستورات💠\n\n🔸ربات\n<i>اعلام وضعیت تبلیغ‌گر ✔️</i>\n<code>❤️ حتی اگر تبلیغ‌گر شما دچار محدودیت ارسال پیام شده باشد بایستی به این پیام پاسخ دهد❤️</code>\n\n🔸افزودن مدیر شناسه\n<i>افزودن مدیر جدید با شناسه عددی داده شده 🛂</i>\n\n🔸افزودن مدیرکل شناسه\n<i>افزودن مدیرکل جدید با شناسه عددی داده شده 🛂</i>\n\n<code>(⚠️ تفاوت مدیر و مدیر‌کل دسترسی به اعطا و یا گرفتن مقام مدیریت است⚠️)</code>\n\n🔸حذف مدیر شناسه\n<i>حذف مدیر یا مدیرکل با شناسه عددی داده شده ✖️</i>\n\n🔸خارج شو\n<i>خارج شدن از گروه و حذف آن از اطلاعات گروه ها 🏃</i>\n\n🔸اد ال مخاطبین\n<i>افزودن حداکثر مخاطبین و افراد در گفت و گوهای شخصی به گروه ➕</i>\n\n🔸شناسه \n<i>دریافت شناسه خود 🆔</i>\n\n🔸بگو متن\n<i>دریافت متن 🗣</i>\n\n🔸ارسال کن "شناسه" متن\n<i>ارسال متن به شناسه گروه یا کاربر داده شده 📤</i>\n\n🔸تنظیم نام "نام" فامیل\n<i>تنظیم نام ربات ✏️</i>\n\n🔸تازه سازی ربات\n<i>تازه‌سازی اطلاعات فردی ربات😌</i>\n<code>(مورد استفاده در مواردی همچون پس از تنظیم نا🅱جهت بروزکردن نام مخاطب اشتراکی تبلیغ‌گر🅰)</code>\n\n🔸تنظیم نام کاربری اسم\n<i>جایگزینی اسم با نام کاربری فعلی(محدود در بازه زمانی کوتاه) 🔄</i>\n\n🔸حذف نام کاربری\n<i>حذف کردن نام کاربری ✘</i>\n\nتوقف عضویت|تایید لینک|شناسایی لینک|افزودن مخاطب\n<i>غیر‌فعال کردن فرایند خواسته شده</i> ◼️\n\n🔸شروع عضویت|تایید لینک|شناسایی لینک|افزودن مخاطب\n<i>فعال‌سازی فرایند خواسته شده</i> ◻️\n\n🔸حداکثر گروه عدد\n<i>تنظیم حداکثر سوپرگروه‌هایی که تبلیغ‌گر عضو می‌شود،با عدد دلخواه</i> ⬆️\n\n🔸حداقل اعضا عدد\n<i>تنظیم شرط حدقلی اعضای گروه برای عضویت,با عدد دلخواه</i> ⬇️\n\n🔸حذف حداکثر گروه\n<i>نادیده گرفتن حدمجاز تعداد گروه</i> ➰\n\n🔸حذف حداقل اعضا\n<i>نادیده گرفتن شرط حداقل اعضای گروه</i> ⚜️\n\n🔸ارسال زمانی ان|اف\n<i>زمان بندی در فروارد و استفاده در دستور ارسال</i> ⏲\n<code>🕐 بعد از فعال‌سازی ,ارسال به 400 مورد حدودا 4 دقیقه زمان می‌برد و  تبلیغ‌گر طی این زمان پاسخگو نخواهد بود 🕐</code>\n\n🔸افزودن با شماره ان|اف\n<i>تغییر وضعیت اشتراک شماره تبلیغ‌گر در جواب شماره به اشتراک گذاشته شده 🔖</i>\n\n🔸افزودن با پیام ان|اف\n<i>تغییر وضعیت ارسال پیام در جواب شماره به اشتراک گذاشته شده ℹ️</i>\n\n🔸تنظیم پیام افزودن مخاطب متن\n<i>تنظیم متن داده شده به عنوان جواب شماره به اشتراک گذاشته شده 📨</i>\n\nلیست مخاطبین|خصوصی|گروه|سوپرگروه|پاسخ های خودکار|لینک|مدیر\n<i>دریافت لیستی از مورد خواسته شده در قالب پرونده متنی یا پیام 💎</i>\n\n🔸مسدودیت شناسه\n<i>مسدود‌کردن(بلاک) کاربر با شناسه داده شده از گفت و گوی خصوصی ☫</i>\n\n🔸رفع مسدودیت شناسه\n<i>رفع مسدودیت کاربر با شناسه داده شده 💢</i>\n\n🔸وضعیت مشاهده ان|اف ☯\n<i>تغییر وضعیت مشاهده پیام‌ها توسط تبلیغ‌گر (فعال و غیر‌فعال‌کردن تیک دوم)</i>\n\n🔸امار\n<i>دریافت آمار و وضعیت تبلیغ‌گر 📊</i>\n\n🔸وضعیت\n<i>دریافت وضعیت اجرایی تبلیغ‌گر⚙️</i>\n\n🔸بارگیری\n<i>بارگیری آمار تبلیغ‌گر🚀</i>\n<code>☻مورد استفاده حداکثر یک بار در روز👽</code>\n\n🔸ارسال به همه|خصوصی|گروه|سوپرگروه\n<i>ارسال پیام جواب داده شده به مورد خواسته شده 📩</i>\n<code>(😕عدم استفاده از همه و خصوصی😇)</code>\n\n🔸ارسال به سوپرگروه متن\n<i>ارسال متن داده شده به همه سوپرگروه ها ✉️</i>\n<code>(😈توصیه ما استفاده و ادغام دستورات بگو و ارسال به سوپرگروه😵)</code>\n\n🔸تنظیم جواب "متن" جواب\n<i>تنظیم جوابی به عنوان پاسخ خودکار به پیام وارد شده مطابق با متن باشد 📃</i>\n\n🔸حذف جواب متن\n<i>حذف جواب مربوط به متن ✖️</i>\n\n🔸پاسخگوی خودکار ان|اف\n<i>تغییر وضعیت پاسخگویی خودکار ربات به متن های تنظیم شده 🚨</i>\n\n🔸حذف لینک عضویت|تایید|ذخیره شده\n<i>حذف لیست لینک‌های مورد نظر </i>✘\n\n🔸حذف کلی لینک عضویت|تایید|ذخیره شده\n<i>حذف کلی لیست لینک‌های مورد نظر </i>💢\n📌<code>پذیرفتن مجدد لینک در صورت حذف کلی</code>📌\n\n🔸اد ال شناسه\n<i>افزودن کابر با شناسه وارد شده به همه گروه و سوپرگروه ها ع✜✛</i>\n\n🔸خارج شو شناسه\n<i>عملیات ترک کردن با استفاده از شناسه گروه 🔚</i>\n\n🔸راهنما\n<i>دریافت همین پیام 🔁</i>\n〰〰〰ا〰〰〰\nسٲزڹڋھ : @Astae_bot\nکانال : @tabchi2611\n<code>گپ پشتمیبانی ما در کانال.</code>'
					return send(msg.chat_id_,msg.id_, txt)
				elseif tostring(msg.chat_id_):match("^-") then
					if text:match("^(خارج شو)$") then
						rem(msg.chat_id_)
						return tdcli_function ({
							ID = "ChangeChatMemberStatus",
							chat_id_ = msg.chat_id_,
							user_id_ = bot_id,
							status_ = {ID = "ChatMemberStatusLeft"},
						}, dl_cb, nil)
					elseif text:match("^(اد ال مخاطبین)$") then
						tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},function(i, naji)
							local users, count = redis:smembers("bot1users"), naji.total_count_
							for n=0, tonumber(count) - 1 do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = naji.users_[n].id_,
									forward_limit_ = 50
								},  dl_cb, nil)
							end
							for n=1, #users do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = users[n],
									forward_limit_ = 50
								},  dl_cb, nil)
							end
						end, {chat_id=msg.chat_id_})
						return send(msg.chat_id_, msg.id_, "<i>در حال ادد شدن، منتظر باشید ...</i>")
					end
				end
			end
			if redis:sismember("bot1answerslist", text) then
				if redis:get("bot1autoanswer") then
					if msg.sender_user_id_ ~= bot_id then
						local answer = redis:hget("bot1answers", text)
						send(msg.chat_id_, 0, answer)
					end
				end
			end
		elseif (msg.content_.ID == "MessageContact" and redis:get("bot1savecontacts")) then
			local id = msg.content_.contact_.user_id_
			if not redis:sismember("bot1addedcontacts",id) then
				redis:sadd("bot1addedcontacts",id)
				local first = msg.content_.contact_.first_name_ or "-"
				local last = msg.content_.contact_.last_name_ or "-"
				local phone = msg.content_.contact_.phone_number_
				local id = msg.content_.contact_.user_id_
				tdcli_function ({
					ID = "ImportContacts",
					contacts_ = {[0] = {
							phone_number_ = tostring(phone),
							first_name_ = tostring(first),
							last_name_ = tostring(last),
							user_id_ = id
						},
					},
				}, dl_cb, nil)
				if redis:get("bot1addcontact") and msg.sender_user_id_ ~= bot_id then
					local fname = redis:get("bot1fname")
					local lnasme = redis:get("bot1lname") or ""
					local num = redis:get("bot1num")
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = msg.id_,
						disable_notification_ = 1,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {
							ID = "InputMessageContact",
							contact_ = {
								ID = "Contact",
								phone_number_ = num,
								first_name_ = fname,
								last_name_ = lname,
								user_id_ = bot_id
							},
						},
					}, dl_cb, nil)
				end
			end
			if redis:get("bot1addmsg") then
				local answer = redis:get("bot1addmsgtext") or "🔸خصوصی پیام بده"
				send(msg.chat_id_, msg.id_, answer)
			end
		elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
			return rem(msg.chat_id_)
		elseif (msg.content_.caption_ and redis:get("bot1link"))then
			find_link(msg.content_.caption_)
		end
		if redis:get("bot1markread") then
			tdcli_function ({
				ID = "ViewMessages",
				chat_id_ = msg.chat_id_,
				message_ids_ = {[0] = msg.id_} 
			}, dl_cb, nil)
		end
	end
end
