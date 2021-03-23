normalise_ext(f) = endswith(f, ".bson.zstd" ) ? f : f * ".bson.zstd"
function bsave(fname, dict)
    open(normalise_ext(fname), "w") do f
        s = ZstdCompressorStream(f)
        bson(s, dict)
        close(s)
    end
end
function bload(fname, mod = @__MODULE__)
    open(normalise_ext(fname)) do f
        s = ZstdDecompressorStream(f)
        res = BSON.load(s, mod)
        close(s)
        res
    end
end
