log_factorials           = {"0": 0};

function log_fact (N) {
    if (N < Abs (log_factorials)) {
        return log_factorials[N];
    }
    
    lastN = log_factorials[Abs (log_factorials)-1];
    for (k = Abs (log_factorials); k <= N; k += 1) {
        log_factorials[k] = Log (k) + log_factorials[k-1];
    }
    
    return log_factorials[N];
    
}



function make_global_var (var_id, val) {
    ExecuteCommands ("global `var_id` = val; `var_id`:<0.999999; `var_id`:>1e-6;");
}

function precompute_mc (coverages) {
    
    sites = Rows (coverages);
    
    for (s = 0; s < sites; s+=1) {
         multinomial_coefficients[s] = log_fact(coverages[s][1]) -
                                       log_fact(coverages[s][2]) -
                                       log_fact(coverages[s][3]) -
                                       log_fact(coverages[s][4]) - 
                                       log_fact(coverages[s][5]);  
    }

    return 0;
}

function multinomial_logL (rates, weights) {
    log_rates = Transpose(Log (rates));
    logL = counts * log_rates;
    result = {sites,1};
    for (k = 0; k < sites; k+=1) {
        thisRow = logL[k][-1];
        minVal = (Min (thisRow*(-1), 1))[0];
        thisRow += minVal;
        result[k] = Log(+(thisRow["Exp(_MATRIX_ELEMENT_VALUE_)"]$weights)) - minVal + multinomial_coefficients[k];
    }
    return +result;
}

function report_site (post,rates,s,stencil) {
    result = {4,1};
    site_post = post[s][-1];
    for (k = 0; k < 4; k+=1) {
        result[k] = +(site_post $ stencil [k][-1]);
    }
    return result;
}

function posterior (rates, weights) {
    log_rates = Transpose(Log (rates));
    logL = counts * log_rates;
    rate_count = Rows (rates);
    
    result = {sites, rate_count};
    
    for (k = 0; k < sites; k+=1) {
        thisRow = logL[k][-1];
        minVal = (Min (thisRow*(-1), 1))[0];
        thisRow += minVal;
        thisRow = thisRow["Exp(_MATRIX_ELEMENT_VALUE_)"]$weights;
        thisRow = thisRow*(1/(+thisRow));
        for (i = 0; i < rate_count; i+=1) {
            result [k][i] = thisRow[i];
        }
    }
    return result;
}

LoadFunctionLibrary ("ReadDelimitedFiles");
LoadFunctionLibrary ("GrabBag");

coverage_data = ReadTabTable ("BB_full.txt", 0);
sites         = Rows         (coverage_data);

multinomial_coefficients = {sites,1};
counts = coverage_data [{{0,2}}][{{sites-1,5}}];

precompute_mc (coverage_data);

per_class = 3;
total     = per_class^4;

rates         = {total,4};
current_class = 0;

weights       = {1, total};

//generate_gdd_freqs (numberOfRates, freqs&, lfMixing&, probPrefix, incrementFlag)
Af = {}; l = "";
generate_gdd_freqs (per_class, "Af", "l", "fA", 0);
Cf = {}; 
generate_gdd_freqs (per_class, "Cf", "l", "fC", 0);
Gf = {}; 
generate_gdd_freqs (per_class, "Gf", "l", "fG", 0);
Tf = {}; 
generate_gdd_freqs (per_class, "Tf", "l", "fT", 0);


init_values = {{0.01,0.05,0.98}};

for (i = 0; i < per_class; i+=1) {
    make_global_var ("A" + i, init_values[i]);
    make_global_var ("C" + i, init_values[i]);
    make_global_var ("G" + i, init_values[i]);
    make_global_var ("T" + i, init_values[i]);
}

T0 := A0;
G0 := A0;
C0 := A0;
stencil = {4, total};

for (A = 0; A < per_class; A+=1) {
    for (C = 0; C < per_class; C+=1) {
        for (G = 0; G < per_class; G+=1) {
            for (T = 0; T < per_class; T+=1) {
                normalizer = "(A" + A + "+C" + C + "+G" + G + "+T" + T + ")";
                ExecuteCommands ("rates[current_class][0] := A" + A + "/`normalizer`");
                ExecuteCommands ("rates[current_class][1] := C" + C + "/`normalizer`");
                ExecuteCommands ("rates[current_class][2] := G" + G + "/`normalizer`");
                ExecuteCommands ("rates[current_class][3] := T" + T + "/`normalizer`");
                ExecuteCommands ("weights[current_class] := " + Af[A] + "*" + Cf[C] + "*" + Gf[G] + "*" + Tf[T]);
                stencil [0][current_class] = A > 0;
                stencil [1][current_class] = C > 0;
                stencil [2][current_class] = G > 0;
                stencil [3][current_class] = T > 0;
                current_class += 1;
            }
        }
    }
}
      
VERBOSITY_LEVEL = 1;
//Optimize (res,multinomial_logL (rates,weights));


rates = {
{0.25,0.25,0.25,0.25}
{0.1498700062643875,0.1498700062643875,0.1498700062643875,0.5503899812068374}
{0.003071814858931835,0.003071814858931835,0.003071814858931835,0.9907845554232045}
{0.1310649853494875,0.1310649853494875,0.6068050439515377,0.1310649853494875}
{0.09706615567434596,0.09706615567434596,0.4493971651018738,0.3564705235494343}
{0.003037941560332874,0.003037941560332874,0.01406507052302663,0.9798590463563076}
{0.002940056391847218,0.002940056391847218,0.9911798308244584,0.002940056391847218}
{0.002917136012873421,0.002917136012873421,0.9834526942237187,0.01071303375053443}
{0.001511327437226616,0.001511327437226616,0.5095131092398735,0.4874642358856733}
{0.1291331776123329,0.6126004671630014,0.1291331776123329,0.1291331776123329}
{0.09600252739393102,0.4554305424660611,0.09600252739393102,0.3525644027460768}
{0.003036888513602305,0.01440682678575275,0.003036888513602305,0.9795193961870425}
{0.08792177966473991,0.4170959337662745,0.4070605069042458,0.08792177966473991}
{0.07119365629609435,0.3377386657126934,0.329612593498002,0.2614550844932104}
{0.003003776959191106,0.01424974745048163,0.01390689515496675,0.9688395804353604}
{0.002908046349941939,0.01379560687226482,0.9803883004278513,0.002908046349941939}
{0.002885620444563561,0.01368921964966746,0.972827865478146,0.01059729442762291}
{0.001502823972026323,0.00712931164824955,0.5066463400098611,0.4847215243698629}
{0.002720588841286121,0.9918382334761414,0.002720588841286121,0.002720588841286121}
{0.002700951209777865,0.9846789915321817,0.002700951209777865,0.009919106048262492}
{0.001451151473061462,0.5290426438958591,0.001451151473061462,0.4680550531580179}
{0.002693985195569589,0.9821394092469588,0.01247262036190194,0.002693985195569589}
{0.002674728385528657,0.9751190024278398,0.01238346512770956,0.009822804058922137}
{0.001443547738701001,0.526270569578177,0.006683341448464362,0.4656025412346576}
{0.001421066136539531,0.5180745084037863,0.4790833593231346,0.001421066136539531}
{0.001415689733376566,0.5161144466205843,0.4772708150493957,0.005199048596643662}
{0.0009753837821377527,0.3555932130411335,0.328830676462228,0.3146007267145008}
{0.8098081362159131,0.06339728792802898,0.06339728792802898,0.06339728792802898}
{0.6924834196135206,0.05421231125655093,0.05421231125655093,0.1990919578733776}
{0.03786841186222295,0.002964596801193957,0.002964596801193957,0.9562023945353891}
{0.6583165561202868,0.05153749683371747,0.2386084502122783,0.05153749683371747}
{0.5786221512840453,0.04529847686873528,0.2097230177379187,0.1663563541093007}
{0.03746525195949557,0.002933034702356969,0.0135793724519885,0.9460223408861589}
{0.03629847616254516,0.002841691558421208,0.9580181407206124,0.002841691558421208}
{0.03602489317129771,0.002820273621390626,0.950797521666689,0.01035731154062262}
{0.01896750784182584,0.001484905500634251,0.5006054941634086,0.4789420924941313}
{0.6544666492728411,0.2430611508376282,0.05123609994476534,0.05123609994476534}
{0.575645840007428,0.2137880371789098,0.04506547098187316,0.165500651831789}
{0.03745271362443878,0.01390949360928112,0.00293205311622294,0.9457057396500572}
{0.5518375830477306,0.2049459329364833,0.2000148852945592,0.04320159872122696}
{0.494720127386595,0.1837331873804831,0.1793125234161169,0.142234161816805}
{0.0370583103732065,0.01376301691983463,0.01343187547606006,0.9357467972308988}
{0.03591635729815668,0.01333890909259458,0.9479329569140957,0.002811776695153016}
{0.03564848282297135,0.01323942368979994,0.940863001538714,0.01024909194851467}
{0.01886264282876397,0.007005361814681493,0.4978378136583015,0.476294181698253}
{0.03367298647539871,0.9610547127819761,0.002636150371312518,0.002636150371312518}
{0.03343742058663249,0.9543314686843712,0.002617708671595942,0.009613402057400345}
{0.01822497198719724,0.520155681213839,0.001426774744387783,0.4601925720545759}
{0.03335383344400139,0.9519458229260931,0.01208917872826133,0.002611164901644176}
{0.03312269646160409,0.9453489834567628,0.01200540256215427,0.009522917519479047}
{0.01813107277411265,0.5174757204884252,0.006571651791370975,0.4578215549460913}
{0.0178533486863925,0.5095492467391625,0.4711997230292341,0.001397681545211032}
{0.01778691043343012,0.5076530443882022,0.4694462320206659,0.005113813157701875}
{0.01231765645083945,0.3515560400666362,0.325097347839768,0.3110289556427563}
{0.989805109119261,0.00339829696024635,0.00339829696024635,0.00339829696024635}
{0.980896823967649,0.003367712153123392,0.003367712153123392,0.01236775172610417}
{0.4729822075724474,0.001623889373206286,0.001623889373206286,0.52377001368114}
{0.9777444861531696,0.003356889234637805,0.01554173537755485,0.003356889234637805}
{0.9690510171907365,0.003327041955737296,0.01540354836035294,0.01221839249317318}
{0.4702105990214578,0.001614373612146817,0.007474231565820586,0.5207007958005747}
{0.4620360883426339,0.001586308072238595,0.5347912955128887,0.001586308072238595}
{0.4600856345664526,0.00157961158110349,0.5325337106009749,0.005801043251469072}
{0.3059715576713798,0.00105049186428397,0.354151828927764,0.3388261215365723}
{0.9773700003175859,0.01591879265688025,0.003355603512766909,0.003355603512766909}
{0.9686831598666997,0.01577730682046607,0.003325778991528926,0.0122137543213052}
{0.4701239715124425,0.007657085876488807,0.001614076194000711,0.5206048664170679}
{0.9656087131294877,0.01572723215055765,0.01534883122354811,0.003315223496406454}
{0.9571287758511577,0.01558911622390426,0.01521403839877178,0.01206806952616613}
{0.4673856624958165,0.007612486008013234,0.0074293277933507,0.5175725237028196}
{0.4593082349592866,0.007480925908856095,0.5316338965961017,0.001576942535755483}
{0.4573806960488707,0.007449531357925527,0.5294028348737361,0.005766937719467744}
{0.3047728913962744,0.004963950667606631,0.3527644128658484,0.3374987450702706}
{0.442764731309572,0.5541949812102946,0.001520143740066628,0.001520143740066628}
{0.4409732743453358,0.5519526696881066,0.001513993132538048,0.005560062834019542}
{0.2973995079283276,0.372245806979268,0.001021061453876395,0.3293336236385279}
{0.4403350408919354,0.5511538125260448,0.006999344695803445,0.001511801886216287}
{0.4385631520336812,0.5489359937996017,0.006971179640266522,0.00552967452645064}
{0.2963013405559921,0.3708712646924937,0.004709857321777402,0.3281175374297368}
{0.2930343669459459,0.3667820944167154,0.339177464017936,0.001006074619402814}
{0.2922486030108203,0.365798577893223,0.3382679685836281,0.003684850512328515}
{0.2214097199409566,0.2771317291228935,0.2562743343081932,0.2451842166279568}
}
;

weights = {
{0.2128532013982862,0.02003192218136826,0.06588747539464214,0.02804948450314271,0.002639777495021383,0.008682555432065453,0.06982747429003916,0.006571564448693417,0.02161469014293155,0.02757858448573682,0.002595460414320168,0.00853679105968887,0.003634265649140081,0.0003420259887647623,0.001124965877714246,0.009047281819031951,0.0008514527578687155,0.002800533674494502,0.04617240876443649,0.004345352069968748,0.0142924016476769,0.006084532699545575,0.000572624159498636,0.001883431848314368,0.01514707161897461,0.001425512785119681,0.004688688269849568,0.0117516392288251,0.001105963739276107,0.003637651843850346,0.001548613881633201,0.0001457422888736157,0.0004793644556512192,0.003855179441633745,0.0003628165048150398,0.001193348462385959,0.001522615460744775,0.000143295539937475,0.0004713167950788963,0.0002006480451778159,1.888327730304945e-05,6.210943999333633e-05,0.0004995010234298877,4.70087626830586e-05,0.0001546176481003601,0.002549181720364148,0.00023990717317401,0.0007890844336547368,0.0003359274499576522,3.161461745433419e-05,0.0001039843960441738,0.0008362708189025084,7.870265449030281e-05,0.0002588627873188281,0.1378332579806706,0.01297168696423224,0.04266548651420901,0.01816346575174236,0.001709389993162584,0.005622395599115409,0.04521683589784664,0.004255421727477273,0.01399660960263541,0.01785853407509467,0.001680692432697844,0.005528005765135052,0.002353371579555896,0.0002214791980379723,0.0007284725389321191,0.005858574457863437,0.0005513589030501519,0.001813487783619796,0.0298989796113482,0.002813836150653573,0.009255055928341197,0.003940043935252007,0.0003708032248688351,0.001219617774749691,0.009808498140477731,0.0009230919252113594,0.003036163776930268}
};


for (i = 0; i < per_class; i+=1) {
    fprintf (stdout, "A", i , " = ", Eval ("A" + i), " (p = ", Eval (Af[i]), ")\n");
    fprintf (stdout, "C", i , " = ", Eval ("C" + i), " (p = ", Eval (Cf[i]), ")\n");
    fprintf (stdout, "G", i , " = ", Eval ("G" + i), " (p = ", Eval (Gf[i]), ")\n");
    fprintf (stdout, "T", i , " = ", Eval ("T" + i), " (p = ", Eval (Tf[i]), ")\n");
}

fprintf (stdout, rates, weights);

post = posterior (rates, weights);

for (site = 0; site < sites; site +=1) {
   pp = report_site (post, rates, site, stencil);
   fprintf (stdout, site+1, ":", pp, "\n");
}