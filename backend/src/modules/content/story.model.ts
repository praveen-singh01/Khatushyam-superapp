import { Schema, model } from "mongoose";

/** Singleton key for the public Shyam Story (खोजें tab). */
export const STORY_KEY = "khatu-shyam-story";

export interface LocalizedText {
  hi: string;
  en: string;
}

export interface StoryChapter {
  title: LocalizedText;
  body: LocalizedText;
}

export interface StoryDocument {
  key: string;
  title: LocalizedText;
  summary: LocalizedText;
  youtubeVideoId: string | null;
  chapters: StoryChapter[];
  updatedBy?: string;
}

const localizedSchema = new Schema<LocalizedText>(
  {
    hi: { type: String, required: true, trim: true },
    en: { type: String, required: true, trim: true },
  },
  { _id: false },
);

const chapterSchema = new Schema<StoryChapter>(
  {
    title: { type: localizedSchema, required: true },
    body: { type: localizedSchema, required: true },
  },
  { _id: false },
);

const storySchema = new Schema<StoryDocument>(
  {
    key: {
      type: String,
      required: true,
      unique: true,
      default: STORY_KEY,
      trim: true,
    },
    title: { type: localizedSchema, required: true },
    summary: { type: localizedSchema, required: true },
    youtubeVideoId: { type: String, default: null, trim: true },
    chapters: {
      type: [chapterSchema],
      default: [],
      validate: {
        validator: (chapters: StoryChapter[]) => chapters.length >= 1,
        message: "At least one chapter is required",
      },
    },
    updatedBy: String,
  },
  { timestamps: true },
);

export const Story = model<StoryDocument>("Story", storySchema);

/** Hinglish-first story copy (hi = what the app shows; en kept as English fallback). */
export const DEFAULT_STORY = {
  title: {
    hi: "Khatu Shyam Baba ki Katha",
    en: "The story of Khatu Shyam Baba",
  },
  summary: {
    hi: "Mahabharat ke Barbarik se Khatu Dham ke Shyam Baba tak — bhakti ki amar katha. Lamba chapters padho, dil se jud jao.",
    en: "From Barbarik of the Mahabharata to Shyam Baba of Khatu — an immortal story of devotion.",
  },
  youtubeVideoId: null as string | null,
  chapters: [
    {
      title: { hi: "Barbarik kaun the?", en: "Who was Barbarik?" },
      body: {
        hi: `Mahabharat ki badi katha mein ek naam aisa hai jisko sunte hi bhakton ke dil mein aastha jag uthti hai — Barbarik. Ve sirf ek yodha nahi the; ve shakti, pratigya aur bhakti ka anokha sangam the. Barbarik Ghatotkach ke putra aur Bhimsen ke pautra the. Yani Pandav-vansh ki usi dhara se jude the jahan veerta peedhi-dar-peedhi chali aayi thi.

Kaha jata hai ki bachpan se hi unmein asadharan bal aur dhanurvidya ka chamatkar dikhta tha. Jahan dusre bacche khel mein time bitate, Barbarik sadhana, practice aur maa ki seekh mein doobe rehte. Unki maa ne unhe sirf shastron ki vidya nahi di, dharma ki samajh bhi di — ki shakti ahankar ke liye nahi, dharma ki raksha ke liye hoti hai.

Time ke saath Barbarik teen divya baanon ke swami bane. Inhi baanon ki wajah se unhe “teen baandhari” kaha jata hai. Lok-aastha kehti hai ki unki capacity itni zabardast thi ki ve akele kisi mahayudh ka faisla badal sakte the. Par asli katha sirf shakti ki nahi hai — asli katha us mann ki hai jo shakti ko Parmeshwar ke charanon mein samarpit kar deta hai.

Aaj jab bhakt “Khatu wale Shyam” ka naam lete hain, to ve usi Barbarik ko pukarte hain jinhone sheesh dekar amarta paayi. Yeh chapter yaad dilata hai — Baba pehle yodha the, phir bhakt bane, aur ant mein Kaliyug ke sabse priya aaradhya. Jai Shree Shyam.`,
        en: `In the vast tapestry of the Mahabharata shines a name that awakens faith — Barbarik. He was not merely a warrior; he was a rare blend of power, vow and devotion. Barbarik was the son of Ghatotkacha and grandson of Bhima.

From childhood he showed extraordinary strength and mastery of the bow. His mother taught him that power exists to protect dharma, never to feed ego. In time he became master of three divine arrows — remembered as the three-arrow warrior.

When devotees call “Khatu Wale Shyam,” they call that same Barbarik who offered his head and became immortal. Jai Shree Shyam.`,
      },
    },
    {
      title: { hi: "Teen baanon ki shakti", en: "Power of three arrows" },
      body: {
        hi: `Barbarik ki katha ka sabse chamatkari hissa unke teen baan hain. Lok-katha kehti hai — pehla baan target ko mark kar leta, doosra use nasht kar deta, aur teesra baan wapas tarkash mein laut aata. Matlab ek baar nishana set ho jaye to fail hone ka sawaal hi nahi. Yeh symbol bhi hai — sankalp, karma aur poornata.

Jab Mahabharat ka mahayudh paas aaya, Barbarik yudhbhoomi ki taraf badhe. Mann mein clear tha ki ve Pandavon ki taraf se dharma-yudh ladna chahte hain. Raste mein Bhagwan Shri Krishna se bhet hui. Krishna ne unki shakti ki pariksha li aur poocha — agar tum lado to kis taraf khade rahoge? Barbarik ne kaha ki ve kamzor paksh ki madad karenge, kyunki sachha yodha anyay ke khilaaf khada hota hai.

Krishna samajh gaye — agar Barbarik maidan mein utre to yudh ka natural flow badal jayega. Unki teen baanon ki shakti itni decisive thi ki kisi bhi taraf ka balance bigad sakta tha. Isliye aage jo hua, woh strategy nahi — bhakti ki pariksha thi. Krishna ne var maanga, aur Barbarik ne bina hichkichahat accept kiya.

Is chapter se seekh milti hai — asli bal baanon mein nahi, samarpan mein hota hai. Jo shakti ko apne ahankar par chadha leta hai woh girta hai; jo shakti ko Prabhu ko saunp deta hai, woh yugon tak pooja jata hai. Baba ki teen baanon ki katha aaj bhi yaad dilati hai ki bhakt jab thaan le to impossible bhi possible ho jata hai — par thaan bhakti ki ho, zid ki nahi. Jai Shree Shyam.`,
        en: `The most wondrous part of Barbarik’s tale is his three arrows. Lore says the first marked the target, the second destroyed it, and the third returned to the quiver.

As the war drew near, Barbarik set out for the Pandavas. Krishna tested him and asked which side he would choose. Barbarik said he would aid the weaker side. Krishna saw that his arrows could unbalance the entire war — so what followed was a test of devotion, not mere strategy.

True strength is not in arrows, but in surrender. Jai Shree Shyam.`,
      },
    },
    {
      title: { hi: "Sheesh daan", en: "The sacrifice of the head" },
      body: {
        hi: `Yeh chapter poori katha ka dil hai — sheesh daan. Bhagwan Shri Krishna ne Barbarik se var maanga ki ve yudh ko yudhbhoomi se hi dekh sakein. Matlab clear tha — Barbarik ko apna sheesh arpit karna hoga. Normal insan ke liye yeh sochna bhi mushkil hai. Par Barbarik bhakt the. Unhone turant haan bol di.

Katha kehti hai ki jab sheesh daan ka pal aaya, teenon lok stabdho ho gaye. Maa ki aankhon mein aansu the, par putra ke dil mein sankoch nahi tha. Unhone Krishna ko prasann karne ko hi param dharma maana. Krishna ne khush hokar var diya — Kaliyug mein tumhari bhakti sabse priya hogi. Tum “Shyam” naam se pooje jaoge. Jo tumhe sache mann se pukarega, uski pukar bekar nahi jayegi.

Sheesh daan sirf balidan nahi tha — yeh ahankar ka poora visarjan tha. Sir matlab abhiman, soch aur “main”. Jo “main” ko utaarkar Prabhu ke charanon mein rakh deta hai, wahi amar ho jata hai. Isliye aaj bhakt Baba ko “Khatu wale Shyam” kehte hain — kyunki usi sheesh ki divya upasthiti Khatu mein virajman maani jati hai.

Jab zindagi mein mushkil faisle aayein, is chapter ko yaad karo. Baba sikhate hain — dene mein nuksaan nahi hota; sachchi bhent wahi hai jo sabse priya ho. Jai Shree Shyam.`,
        en: `This chapter is the heart of the story — the offering of the head. Krishna asked for the boon of watching the war from the battlefield. Barbarik accepted at once.

Krishna blessed him — in Kaliyuga your devotion will be dearest; you will be worshipped as Shyam. Whoever calls you with a true heart will not call in vain.

The head-offering was the dissolving of ego. That is why devotees call Baba “Khatu Wale Shyam.” Jai Shree Shyam.`,
      },
    },
    {
      title: { hi: "Khatu mein virajman", en: "Enshrined at Khatu" },
      body: {
        hi: `Sheesh daan ke baad divya katha Khatu Dham tak pahunchti hai. Aastha kehti hai ki Bhagwan ki kripa se Barbarik ka sheesh Rajasthan ki pavitra dharti — Khatu — mein virajman hua. Aaj yeh jagah crores bhakton ka teerth hai. Sikar district mein basa Khatu Dham door-door se aane wale yatrioin ke liye sirf mandir nahi, ghar jaisa lagta hai.

Mandir parisar mein jab aarti ki ghanti bajti hai, mahaul badal jata hai. Log line mein khade hokar darshan ki wait karte hain — kisaan, businessman, student, budhe, bacche. Koi naukri maangne aaya hai, koi sehat ke liye, koi sirf “Jai Shree Shyam” bolkar mann halka karne. Baba sabko barabar nazar se dekhte hain — yahi bhakton ka experience hai.

Yahan katha aur living history ek ho jate hain. Peedhiyan batati hain ki kaise mushkil time mein Baba ne raah dikhayi, kaise saatwara poora hone par rahat mili, kaise pehli baar darshan karte hi aansu chhalak pade. Yeh experiences lab proof nahi maangte; yeh dil ki sachchai hain.

Agar aap abhi tak Khatu nahi gaye, to bhi yeh chapter aapke andar yatra shuru kar sakta hai. Aur agar ja chuke ho, to yaad taaza kar lo — woh dhool, woh bheed, woh jaighosh, aur woh shanti jo darshan ke baad mann mein utarti hai. Jai Shree Shyam.`,
        en: `After the head-offering, the tale reaches Khatu Dham in Sikar, Rajasthan. Crores of devotees seek darshan here. When the aarti bell rings, the air changes — farmers, students, elders, children wait in line.

Baba looks on all with equal grace. Whether you have visited or not, this chapter can begin the journey within. Jai Shree Shyam.`,
      },
    },
    {
      title: { hi: "Aaj ki bhakti", en: "Devotion today" },
      body: {
        hi: `Kaliyug mein bhakti mushkil nahi — bhakti simple hai, par continuity mushkil hai. Khatu Shyam Baba ki mahima yahi hai ki ve simple dil ko accept karte hain. Aaj ki bhakti ka matlab sirf mandir pahunchna nahi. Ghar ki chhoti si chowki par deep jalana, subah-shaam “Jai Shree Shyam” japna, kisi zarooratmand ki madad karna, maa-baap ka samman — yeh sab Baba ki seva hai.

Ekadashi, Amavasya, Shanivar aur special utsavon par Khatu Dham mein bheed lagti hai. Par Baba sikhate hain — bheed mein hona zaroori nahi, bhaav mein hona zaroori hai. Agar aap door shehar mein ho, kaam ka pressure hai, sehat saath nahi de rahi — tab bhi naam jap band mat karo. Ek minute ka sachcha smaran bhi din badal sakta hai.

Aaj ki generation mobile par bhajan sunti hai, live darshan dekhti hai, Samuday mein apni katha likhti hai. Yeh bhi bhakti ka naya roop hai. Important yeh hai ki tech suvidha bane, distraction nahi. Aarti ke time phone scroll karne se better hai do minute aankhein moondkar Baba ko yaad karna.

Is chapter ko apne daily rule se jodo — chhota sa vrat, roz ka jap, hafte mein ek bhajan. Dheere-dheere mann shant hoga. Baba paas hain; humein yaad rakhna hai. Jai Shree Shyam.`,
        en: `In Kaliyuga devotion is simple; continuity is hard. Lighting a lamp at home, chanting Jai Shree Shyam, helping someone in need — all of this is Baba’s seva.

Being in the crowd is not essential; being in feeling is. Even one minute of sincere remembrance can change a day. Jai Shree Shyam.`,
      },
    },
    {
      title: { hi: "Phalgun Mela aur Gyaras", en: "Phalgun Mela and Gyaras" },
      body: {
        hi: `Phalgun Shukla Ekadashi — bhakt ise Gyaras kehte hain — Khatu Dham ka sabse bhavya parv hai. Door-door se bhakt paidal nikalte hain, koi bus se, koi train se. Sadkon par “Jai Shree Shyam” goonjta hai. Mela sirf mela nahi; yeh collective bhakti ka mahasagar hai.

Gyaras ki raat mandir parisar sota nahi. Kirtan, bhajan, aarti aur wait ki lambi lines — phir bhi chehron par thakaan kam, josh zyada dikhta hai. Budhe lathi pakde khade hain, maayein bacchon ko kandhe par liye hain, jawaan seva mein paani baant rahe hain. Yahan jaat-paat mit jati hai; sab ek hi pukar mein ghul jate hain.

Kaha jata hai ki is din Baba special kripa karte hain. Kaii bhakt apni life-story Gyaras se jodkar sunate hain — naukri lagna, bimari mein rahat, ghar mein sulah. Chahe aap mele mein pahucho ya ghar baithe vrat rakho, bhaav rakho ki aap bhi usi dhara mein ho.

Agar pehli baar jana ho to taiyari rakho — paani, halka khana, patience, aur sabse zaroori — namrata. Bheed mein dhakka nahi, seva ka bhaav. Baba wahin milte hain jahan patience toot’ta nahi. Jai Shree Shyam.`,
        en: `Phalgun Shukla Ekadashi — Gyaras — is Khatu Dham’s grandest festival. Devotees arrive from afar; the night does not sleep for kirtan and aarti. It is said Baba grants special grace this day. Prepare with patience and humility. Jai Shree Shyam.`,
      },
    },
    {
      title: { hi: "Khatu aane ka raasta", en: "The path to Khatu" },
      body: {
        hi: `Khatu Dham Rajasthan ke Sikar district mein hai. Delhi, Jaipur, Haryana, UP — har taraf se bhakt pahuchte hain. General route yeh hai ki pehle Sikar ya Ringas pahucho, phir wahan se Khatu mandir ke liye local bus, taxi ya auto lo. Safar chhota lagta hai jab mann mein Baba bas jaayein.

Train se aane wale aksar Ringas Junction use karte hain. Bus se aane wale Jaipur ke Sindhi Camp ya Delhi ke bus addon se Sikar ki taraf nikalte hain. Raste mein chhoti chai ki dukanein, bhajan ki awaazein, aur anjaan musafiron ka “Jai Shree Shyam” — yatra khud teerth ban jati hai.

Pehli baar aane walon ke liye tips — halka saamaan rakho, cash aur digital dono options rakho, bheed ke time patience rakho, aur local logon se rasta poochhne mein sankoch mat karo. Mandir ke aaspaas prasad, rukne ke jagah aur suvidhaayein asani se mil jati hain.

Par yaad rakho — asli pahunch pairon se nahi, shraddha se hoti hai. Jo ghar baithe roz Baba ko yaad karta hai, woh bhi path par hai. Jo Khatu pahunchkar bhi mann mein shikayat lekar ghumta hai, woh doori tay karke bhi door reh sakta hai. Raasta bahar bhi hai, andar bhi. Jai Shree Shyam.`,
        en: `Khatu Dham is in Sikar district, Rajasthan. Reach Sikar or Ringas first, then take a local bus or taxi to the temple. True arrival is by faith, not only by feet. Jai Shree Shyam.`,
      },
    },
    {
      title: { hi: "Saatwara aur manokamna", en: "Saatwara and wishes" },
      body: {
        hi: `Saatwara Khatu Shyam bhakti ki bahut priya parampara hai — saat Shanivar lagatar Baba ka smaran, bhajan, aarti ya mandir jana. Kaii bhakt saat Shanivar vrat rakhte hain, koi saat din naam jap badhate hain, koi saat baar Baba ki katha sunte hain. Form alag ho sakte hain; bhaav ek hai — continuity.

Aastha kehti hai ki sache mann se kiya saatwara manokamna poori karta hai. Par Baba ka sikhavan isse gehra hai. Agar saatwara sirf “len-den” ban jaye — ki maine saat Shanivar kar diye, ab fal do — to bhakti business ban jati hai. Sachcha saatwara vinay sikhata hai: main try karunga, fal aapki marzi.

Kaii log saatwara ke dauran apni aadatein badalte hain — jhoot kam bolna, kisi ki ninda na karna, ek chhota daan, family se meetha bolna. Yeh bahar ki reeti se bade changes hain. Manokamna kabhi naukri hoti hai, kabhi sehat, kabhi ghar ki shanti. Baba aksar waisa dete hain jiski waakai zaroorat ho — kabhi waisa nahi jo josh mein maanga ho.

Agar aap saatwara shuru karo to likhkar rakho — saat Shanivar ki dates, chhota rule, aur ant mein shukriya. Chahe ichha poori ho ya raah badle, kritagyata rakhna hi bhakti hai. Jai Shree Shyam.`,
        en: `Saatwara is seven consecutive Saturdays of remembrance, bhajan or temple visits. Sincere Saatwara is said to fulfill wishes — but it must be humility, not a bargain. Gratitude itself is devotion. Jai Shree Shyam.`,
      },
    },
    {
      title: { hi: "Shyam naam ki mahima", en: "Glory of Shyam's name" },
      body: {
        hi: `Kaliyug mein sabse simple sadhan naam jap hai. “Shyam” naam chhota hai, par bhakton ke experience mein yeh asem shanti deta hai. Ghar par, raste par, office ki busy life mein — mann mein “Jai Shree Shyam” dohrana kisi ko dikhai nahi deta, par andar deep jal jata hai.

Katha kehti hai — jo ek baar sache dil se Baba ko pukarta hai, Baba use apna lete hain. Pukar ka matlab shor nahi; pukar ka matlab vishwas hai. Kabhi aankhon mein aansu lekar, kabhi muskaan lekar, kabhi nirasha ke beech ek baar naam — yahi darwaza kholta hai.

Naam jap ki ek simple method apnao. Roz ek fixed time choose karo — subah uthkar ya sone se pehle. Gyarah baar, ikkis baar ya mala bharkar jap karo. Beech mein mann bhatke to dosh mat do; naam par laut aao. Dheere-dheere jap swabhav ban jayega.

Bhajan sunna bhi naam ki mahima badhata hai. Jab Samuday mein koi chamatkar ki katha share karta hai, to naam aur jeevant ho jata hai. Aap bhi agar kabhi kripa feel karo to vinamrata se share karo — taaki kisi aur ka vishwas jaage. Ant mein ek hi baat rehti hai — Shyam naam satya hai, Shyam saath hain. Jai Shree Shyam.`,
        en: `In Kaliyuga the simplest means is Name-chant. Repeating Jai Shree Shyam within lights a lamp inside. Whoever calls Baba once with a true heart, Baba makes them His own. Jai Shree Shyam.`,
      },
    },
  ],
} as const;

export function toStoryResponse(doc: {
  title: LocalizedText;
  summary: LocalizedText;
  youtubeVideoId?: string | null;
  chapters: StoryChapter[];
  updatedAt?: Date;
}) {
  const youtubeVideoId =
    doc.youtubeVideoId && doc.youtubeVideoId.trim()
      ? doc.youtubeVideoId.trim()
      : null;
  return {
    title: doc.title,
    summary: doc.summary,
    youtubeVideoId,
    chapters: doc.chapters,
    access: "free" as const,
    updatedAt: doc.updatedAt ?? null,
  };
}
