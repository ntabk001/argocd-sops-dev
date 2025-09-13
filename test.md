```
#!/bin/bash

for file in *; do
    if [ -f "$file" ] && [ "$file" != "encode_all.sh" ] && [ "$file" != "decode_all.sh" ]; then
        encoded_data=$(base64 -w 0 "$file")
        for i in {2..10}; do
            encoded_data=$(echo -n "$encoded_data" | base64 -w 0)
        done
        echo -n "$encoded_data" > "encoded_$file"
    fi
done

```
