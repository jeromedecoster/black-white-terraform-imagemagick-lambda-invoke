const cp = require('child_process')
const fsp = require('fs').promises
const AWS = require('aws-sdk')
const util = require('util')
const path = require('path')

const exec = util.promisify(cp.exec)
const s3 = new AWS.S3({ apiVersion: '2006-03-01' })

exports.handler = async (event) => {
  let record = event.Records[0]

  let rand = Math.random().toString(32).substr(2)
  let basename = path.basename(record.s3.object.key)

  let data = {
    region: record.awsRegion,
    bucket: record.s3.bucket.name,
    key: record.s3.object.key,

    input: `/tmp/${rand}`,
    output: `/tmp/gray-${rand}`,
    converted: `converted/${basename}`
  }

  try {

    await getObjectToTmp(data)
    await exec(`/opt/bin/convert ${data.input} -colorspace Gray ${data.output}`)
    await putGrayObject(data)

    return {
      statusCode: 200,
      body: `https://${data.bucket}.s3.${data.region}.amazonaws.com/${data.converted}`,
    }

  } catch (err) {
    throw new Error(err)
  }
}

// get an object from S3 and write it to /tmp
async function getObjectToTmp(data) {
  let result = await s3
    .getObject({
      Bucket: data.bucket,
      Key: data.key
    })
    .promise()

  return fsp.writeFile(data.input, result.Body)
}

// put an object from /tmp to S3
async function putGrayObject(data) {
  let body = await fsp.readFile(data.output)

  return s3
    .putObject({
      Body: body,
      Bucket: data.bucket,
      Key: data.converted,
      ACL: 'public-read',
      ContentType: 'image/jpeg'
    })
    .promise()
}