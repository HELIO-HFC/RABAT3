PRO asset_rabat3_threshold,stats_file, $
                           bad_rate=bad_rate

if not (keyword_set(stats_file)) then begin
   message,/INFO,'Call is:'
   print,'asset_rabat3_threshold,stats_file,bad_rate=bad_rate'
   return
endif
if not keyword_set(bad_rate) then bad_rate=0.1

data = read_rabat3_train_stats(stats_file,header)

t3 = [data.good,data.miss]
ht = histogram(t3,binsize=1,locations=xt)
hg = histogram(data.good,binsize=1,locations=xg)
hb = histogram(data.bad,binsize=1,locations=xb)
hm = histogram(data.miss,binsize=1,locations=xm)

loadct,39
plot,xt,ht,psym=10,xr=[0,256]
oplot,xb,hb,psym=10,color=254
oplot,xm,hm,psym=10,color=50

stop
END
