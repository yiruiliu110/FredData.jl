isdefined(Base, :__precompile__) && __precompile__()

module FredData

using Requests
using DataFrames
import Requests: get
import JSON

export Fred, get_api_url, set_api_url!, get_api_key
export FredSeries, id, title, units_short, units, seas_adj_short, seas_adj, freq_short, 
       freq, realtime_start, realtime_end, last_updated, notes, trans_short, df
export get_data

const MAX_ATTEMPTS = 3
const FIRST_REALTIME = Date(1776,07,04)
const LAST_REALTIME  = Date(9999,12,31)
const DEFAULT_API_URL = "http://api.stlouisfed.org/fred/"
const API_KEY_LENGTH  = 32

# Fred connection type
"""
A connection to the Fred API.

Constructors
------------
- `Fred()`                     # Default connection, reading from ~/.freddatarc
- `Fred(key::AbstractString)`  # Custom connection

Arguments
---------
- `key`: Registration key provided by the Fred.

Notes
-----
- Set the API url with `set_api_url!(f::Fred, url::AbstractString)`
"""
type Fred
    key::AbstractString
    url::AbstractString
end
Fred(key) =  Fred(key, DEFAULT_API_URL)
function Fred()
    key = ""
    try
        open(joinpath(homedir(),".freddatarc"), "r") do f
            key = readall(f)
        end
        key = rstrip(key)
        @printf "API key loaded.\n"
    catch err
        @printf STDERR "Add Fred API key to ~/.freddatarc\n"
        rethrow(err)
    end

    # Key validation
    if length(key) > API_KEY_LENGTH
        key = key[1:API_KEY_LENGTH]
        warn("Key too long. First ", API_KEY_LENGTH, " chars used.")
    end
    if !isxdigit(key)
        error("Invalid FRED API key: ", key)
    end

    return Fred(key)
end
get_api_key(f::Fred) = f.key
get_api_url(f::Fred) = f.url
set_api_url!(f::Fred, url::AbstractString) = setfield!(f, :url, url)

"""
```
FredSeries(...)
```

Represent a single data series, and all associated metadata, return from Fred.

### Field access
- `id(f)`
- `title(f)`
- `units_short(f)`
- `units(f)`
- `seas_adj_short(f)`
- `seas_adj(f)`
- `freq_short(f)`
- `freq(f)`
- `realtime_start(f)`
- `realtime_end(f)`
- `last_updated(f)`
- `notes(f)`
- `trans_short(f)`
- `df(f)`

"""
immutable FredSeries
    # From series query
    id::AbstractString
    title::AbstractString
    units_short::AbstractString
    units::AbstractString
    seas_adj_short::AbstractString
    seas_adj::AbstractString
    freq_short::AbstractString
    freq::AbstractString
    realtime_start::AbstractString
    realtime_end::AbstractString
    last_updated::DateTime
    notes::AbstractString

    # From series/observations query
    trans_short::AbstractString # "units"
    df::DataFrames.DataFrame
end
id(f::FredSeries) = f.id
title(f::FredSeries) = f.title
units_short(f::FredSeries) = f.units_short
units(f::FredSeries) = f.units
seas_adj_short(f::FredSeries) = f.seas_adj_short
seas_adj(f::FredSeries) = f.seas_adj
freq_short(f::FredSeries) = f.freq_short
freq(f::FredSeries) = f.freq
realtime_start(f::FredSeries) = f.realtime_start
realtime_end(f::FredSeries) = f.realtime_end
last_updated(f::FredSeries) = f.last_updated
notes(f::FredSeries) = f.notes
trans_short(f::FredSeries) = f.trans_short
df(f::FredSeries) = f.df

include("get_data.jl")

end # module
