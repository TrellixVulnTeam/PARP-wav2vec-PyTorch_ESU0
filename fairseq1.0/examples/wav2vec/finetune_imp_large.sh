#!/bin/bash
# finetune the ticket on english asr
# make sure to have run run.sh and oneshot.sh

stage=$1
rewind_init=$2
mask_name=$3

if [ $stage -eq 2 ]; then
	## IMP fine-tuning
    # fine-tuning libri960_big on 100 hr and validate on dev-other
    pretrained_model=libri960_big
    train_subset=train-clean-100
    valid_subset=dev-other
    expdir=exp/${pretrained_model}-finetune-${train_subset}-oneshot/${mask_name}
    datadir=data/${train_subset}
    mask_file=exp/${pretrained_model}-finetune-${train_subset}/oneshot/${mask_name}.pt

    mkdir -p $expdir

    python src/train_with_oneshot.py \
        --distributed-world-size 2 \
        --distributed-port 0 \
        $datadir \
        --save-dir $expdir \
        --post-process letter \
        --train-subset $train_subset \
        --valid-subset $valid_subset \
        --no-epoch-checkpoints \
        --best-checkpoint-metric wer \
        --num-workers 8 \
        --max-update 10000 \
        --sentence-avg \
        --task audio_pretraining \
        --arch wav2vec_ctc_oneshot \
        --w2v-path /data/sls/temp/clai24/pretrained-models/updated_wav2vecs/${pretrained_model}.pt \
        --labels ltr \
        --apply-mask \
        --mask-selection static \
        --mask-other 0 \
        --mask-length 10 \
        --mask-prob 0.5 \
        --mask-channel-selection static \
        --mask-channel-other 0 \
        --mask-channel-length 64 \
        --mask-channel-prob 0.512 \
        --zero-infinity \
        --feature-grad-mult 0.0 \
        --freeze-finetune-updates 0 \
        --validate-after-updates 0 \
        --optimizer adam \
        --adam-betas '(0.9, 0.98)' \
        --adam-eps 1e-08 \
        --lr 3e-05 \
        --lr-scheduler tri_stage \
        --warmup-steps 8000 \
        --hold-steps 32000 \
        --decay-steps 40000 \
        --final-lr-scale 0.05 \
        --final-dropout 0.0 \
        --dropout 0.0 \
        --activation-dropout 0.1 \
        --layerdrop 0.05 \
        --criterion ctc \
        --attention-dropout 0.0 \
        --max-tokens 3000000 \
        --seed 2337 \
        --log-format json \
        --log-interval=200 \
        --ddp-backend no_c10d \
        --save-interval-updates 200 \
        --save-interval 200  \
        --keep-interval-updates 1 \
        --update-freq 5 \
        --validate-interval-updates 200 \
        --validate-interval 200 \
        --mask-file $mask_file \
        2>&1 | tee $expdir/train.log
fi


if [ $stage -eq 3 ]; then
    echo "IMP fine-tuning on 10hr starting from $rewind_init with target prune rate of $target_prune_rate"
    pretrained_model=libri960_big
    train_subset=train-10h
    valid_subset=dev-other
    expdir=exp/${pretrained_model}-finetune-${train_subset}-imp/${rewind_init}/${mask_name}
    datadir=data/${train_subset}
    mask_file=exp/${pretrained_model}-finetune-${train_subset}/imp/${rewind_init}/bert_1.0_mask/${mask_name}.pt
    rewind_init_ckpt=exp/${pretrained_model}-finetune-${train_subset}/${rewind_init}.pt

    [ ! -f $mask_file ] && echo "$mask_file does not exist" && exit 0

    mkdir -p $expdir

    python src/train_with_oneshot.py \
        --distributed-world-size 4 \
        --distributed-port 0 \
        $datadir \
        --save-dir $expdir \
        --post-process letter \
        --train-subset $train_subset \
        --valid-subset $valid_subset \
        --no-epoch-checkpoints \
        --best-checkpoint-metric wer \
        --num-workers 4 \
        --max-update 16000 \
        --sentence-avg \
        --task audio_pretraining \
        --arch wav2vec_ctc_oneshot \
        --w2v-path /nobackup/users/clai24/pretrained-models/updated_wav2vecs/${pretrained_model}.pt \
        --labels ltr \
        --apply-mask \
        --mask-selection static \
        --mask-other 0 \
        --mask-length 10 \
        --mask-prob 0.65 \
        --mask-channel-selection static \
        --mask-channel-other 0 \
        --mask-channel-length 64 \
        --mask-channel-prob 0.256 \
        --zero-infinity \
        --feature-grad-mult 0.0 \
        --freeze-finetune-updates 0 \
        --validate-after-updates 0 \
        --optimizer adam \
        --adam-betas '(0.9, 0.98)' \
        --adam-eps 1e-08 \
        --lr 1e-04 \
        --lr-scheduler tri_stage \
        --warmup-steps 1600 \
        --hold-steps 6400 \
        --decay-steps 8000 \
        --final-lr-scale 0.05 \
        --final-dropout 0.0 \
        --dropout 0.0 \
        --activation-dropout 0.1 \
        --layerdrop 0.1 \
        --criterion ctc \
        --attention-dropout 0.0 \
        --max-tokens 600000 \
        --seed 2337 \
        --log-format json \
        --log-interval=200 \
        --ddp-backend no_c10d \
        --save-interval-updates 20 \
        --save-interval 20 \
        --keep-interval-updates 1 \
        --update-freq 5 \
        --validate-interval-updates 20 \
        --validate-interval 20 \
        --mask-file $mask_file \
        2>&1 | tee $expdir/train.log
fi

if [ $stage -eq 4 ]; then
    echo "IMP fine-tuning on 1hr starting from $rewind_init with target prune rate of $target_prune_rate"
    pretrained_model=libri960_big
    train_subset=train-1h
    valid_subset=dev-other
    expdir=exp/${pretrained_model}-finetune-${train_subset}-imp/${rewind_init}/${mask_name}
    datadir=data/${train_subset}
    mask_file=exp/${pretrained_model}-finetune-${train_subset}/imp/${rewind_init}/bert_1.0_mask/${mask_name}.pt
    rewind_init_ckpt=exp/${pretrained_model}-finetune-${train_subset}/${rewind_init}.pt

    [ ! -f $mask_file ] && echo "$mask_file does not exist" && exit 0

    mkdir -p $expdir

    python -u src/train_with_oneshot.py \
        --distributed-world-size 4 \
        --distributed-port 0 \
        $datadir \
        --save-dir $expdir \
        --post-process letter \
        --train-subset $train_subset \
        --valid-subset $valid_subset \
        --no-epoch-checkpoints \
        --best-checkpoint-metric wer \
        --num-workers 4 \
        --max-update 15000 \
        --sentence-avg \
        --task audio_pretraining \
        --arch wav2vec_ctc_oneshot \
        --w2v-path /nobackup/users/clai24/pretrained-models/updated_wav2vecs/${pretrained_model}.pt \
        --labels ltr \
        --apply-mask \
        --mask-selection static \
        --mask-other 0 \
        --mask-length 10 \
        --mask-prob 0.75 \
        --mask-channel-selection static \
        --mask-channel-other 0 \
        --mask-channel-length 64 \
        --mask-channel-prob 0.256 \
        --zero-infinity \
        --feature-grad-mult 0.0 \
        --freeze-finetune-updates 10000 \
        --validate-after-updates 10000 \
        --optimizer adam \
        --adam-betas '(0.9, 0.98)' \
        --adam-eps 1e-08 \
        --lr 5e-05 \
        --lr-scheduler tri_stage \
        --warmup-steps 1500 \
        --hold-steps 6000 \
        --decay-steps 7500 \
        --final-lr-scale 0.05 \
        --final-dropout 0.0 \
        --dropout 0.0 \
        --activation-dropout 0.1 \
        --layerdrop 0.1 \
        --criterion ctc \
        --attention-dropout 0.0 \
        --max-tokens 600000 \
        --seed 2337 \
        --log-format json \
        --log-interval=200 \
        --ddp-backend no_c10d \
        --save-interval-updates 150 \
        --save-interval 150 \
        --keep-interval-updates 1 \
        --update-freq 5 \
        --validate-interval-updates 150 \
        --validate-interval 150 \
        --mask-file $mask_file \
        2>&1 | tee $expdir/train.log
fi

if [ $stage -eq 5 ]; then
    echo "IMP fine-tuning on 10min starting from $rewind_init with target prune rate of $target_prune_rate"
    pretrained_model=libri960_big
    train_subset=train-10min-0
    valid_subset=dev-other
    expdir=exp/${pretrained_model}-finetune-${train_subset}-imp/${rewind_init}/${mask_name}
    datadir=data/${train_subset}
    mask_file=exp/${pretrained_model}-finetune-${train_subset}/imp/${rewind_init}/bert_1.0_mask/${mask_name}.pt
    rewind_init_ckpt=exp/${pretrained_model}-finetune-${train_subset}/${rewind_init}.pt

    [ ! -f $mask_file ] && echo "$mask_file does not exist" && exit 0

    mkdir -p $expdir

    python -u src/train_with_oneshot.py \
        --distributed-world-size 4 \
        --distributed-port 0 \
        $datadir \
        --save-dir $expdir \
        --post-process letter \
        --train-subset $train_subset \
        --valid-subset $valid_subset \
        --no-epoch-checkpoints \
        --best-checkpoint-metric wer \
        --num-workers 4 \
        --max-update 12000 \
        --sentence-avg \
        --task audio_pretraining \
        --arch wav2vec_ctc_oneshot \
        --w2v-path /nobackup/users/clai24/pretrained-models/updated_wav2vecs/${pretrained_model}.pt \
        --labels ltr \
        --apply-mask \
        --mask-selection static \
        --mask-other 0 \
        --mask-length 10 \
        --mask-prob 0.75 \
        --mask-channel-selection static \
        --mask-channel-other 0 \
        --mask-channel-length 64 \
        --mask-channel-prob 0.512 \
        --zero-infinity \
        --feature-grad-mult 0.0 \
        --freeze-finetune-updates 10000 \
        --validate-after-updates 10000 \
        --optimizer adam \
        --adam-betas '(0.9, 0.98)' \
        --adam-eps 1e-08 \
        --lr 5e-05 \
        --lr-scheduler tri_stage \
        --warmup-steps 1200 \
        --hold-steps 4800 \
        --decay-steps 6000 \
        --final-lr-scale 0.05 \
        --final-dropout 0.0 \
        --dropout 0.0 \
        --activation-dropout 0.1 \
        --layerdrop 0.1 \
        --criterion ctc \
        --attention-dropout 0.0 \
        --max-tokens 600000 \
        --seed 2337 \
        --log-format json \
        --log-interval=200 \
        --ddp-backend no_c10d \
        --save-interval-updates 300 \
        --save-interval 300 \
        --keep-interval-updates 1 \
        --update-freq 5 \
        --validate-interval-updates 300 \
        --validate-interval 300 \
        --mask-file $mask_file \
        2>&1 | tee $expdir/train.log
fi

